package com.halohub.frankenstein.chat;

import com.alibaba.fastjson2.JSON;
import com.halohub.frankenstein.common.enums.ChatSenderType;
import com.halohub.frankenstein.satoken.StpAdminUtil;
import com.halohub.frankenstein.satoken.StpMemberUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.util.Map;

@Component
@Slf4j
public class ChatWebSocketHandler extends TextWebSocketHandler {

    public static final String ATTR_TYPE = "chatSenderType";
    public static final String ATTR_ID = "chatSenderId";

    private final ChatSessionHub chatSessionHub;

    public ChatWebSocketHandler(ChatSessionHub chatSessionHub) {
        this.chatSessionHub = chatSessionHub;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Map<String, String> query = parseQuery(session.getUri());
        String clientType = query.get("type");
        String token = normalizeToken(query.get("token"));
        if (!StringUtils.hasText(clientType) || !StringUtils.hasText(token)) {
            chatSessionHub.closeQuietly(session, CloseStatus.NOT_ACCEPTABLE);
            return;
        }
        try {
            ChatSenderType senderType;
            long loginId;
            if ("admin".equalsIgnoreCase(clientType)) {
                Object id = StpAdminUtil.getStpLogic().getLoginIdByToken(token);
                if (id == null) {
                    chatSessionHub.closeQuietly(session, CloseStatus.NOT_ACCEPTABLE);
                    return;
                }
                senderType = ChatSenderType.ADMIN;
                loginId = Long.parseLong(String.valueOf(id));
            } else if ("user".equalsIgnoreCase(clientType) || "member".equalsIgnoreCase(clientType)) {
                Object id = StpMemberUtil.getStpLogic().getLoginIdByToken(token);
                if (id == null) {
                    chatSessionHub.closeQuietly(session, CloseStatus.NOT_ACCEPTABLE);
                    return;
                }
                senderType = ChatSenderType.MEMBER;
                loginId = Long.parseLong(String.valueOf(id));
            } else {
                chatSessionHub.closeQuietly(session, CloseStatus.NOT_ACCEPTABLE);
                return;
            }
            session.getAttributes().put(ATTR_TYPE, senderType);
            session.getAttributes().put(ATTR_ID, loginId);
            chatSessionHub.register(senderType, loginId, session);
            session.sendMessage(new TextMessage(JSON.toJSONString(Map.of(
                    "event", "CONNECTED",
                    "targetType", senderType.name(),
                    "targetId", loginId
            ))));
            log.debug("Chat WS connected: {} {}", senderType, loginId);
        } catch (Exception ex) {
            log.warn("Chat WS auth failed", ex);
            chatSessionHub.closeQuietly(session, CloseStatus.NOT_ACCEPTABLE);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // Heartbeat / ping only; business messages go through HTTP
        String payload = message.getPayload();
        if ("ping".equalsIgnoreCase(payload)) {
            try {
                session.sendMessage(new TextMessage("pong"));
            } catch (Exception ignored) {
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        ChatSenderType type = (ChatSenderType) session.getAttributes().get(ATTR_TYPE);
        Long id = (Long) session.getAttributes().get(ATTR_ID);
        if (type != null && id != null) {
            chatSessionHub.unregister(type, id, session);
        }
    }

    private String normalizeToken(String token) {
        if (!StringUtils.hasText(token)) {
            return token;
        }
        if (token.regionMatches(true, 0, "Bearer ", 0, 7)) {
            return token.substring(7).trim();
        }
        return token.trim();
    }

    private Map<String, String> parseQuery(URI uri) {
        Map<String, String> map = new java.util.HashMap<>();
        if (uri == null || uri.getQuery() == null) {
            return map;
        }
        for (String part : uri.getQuery().split("&")) {
            int idx = part.indexOf('=');
            if (idx > 0) {
                map.put(part.substring(0, idx), java.net.URLDecoder.decode(
                        part.substring(idx + 1), java.nio.charset.StandardCharsets.UTF_8));
            }
        }
        return map;
    }
}
