package com.halohub.frankenstein.chat;

import com.halohub.frankenstein.common.enums.ChatSenderType;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

@Component
public class ChatSessionHub {

    private final Map<String, Set<WebSocketSession>> sessions = new ConcurrentHashMap<>();

    public static String key(ChatSenderType type, Long id) {
        return type.name() + ":" + id;
    }

    public void register(ChatSenderType type, Long id, WebSocketSession session) {
        sessions.computeIfAbsent(key(type, id), k -> new CopyOnWriteArraySet<>()).add(session);
    }

    public void unregister(ChatSenderType type, Long id, WebSocketSession session) {
        String k = key(type, id);
        Set<WebSocketSession> set = sessions.get(k);
        if (set == null) {
            return;
        }
        set.remove(session);
        if (set.isEmpty()) {
            sessions.remove(k);
        }
    }

    public void sendTo(ChatSenderType type, Long id, String json) {
        Set<WebSocketSession> set = sessions.get(key(type, id));
        if (set == null || set.isEmpty()) {
            return;
        }
        TextMessage message = new TextMessage(json);
        for (WebSocketSession session : set) {
            if (session.isOpen()) {
                try {
                    synchronized (session) {
                        session.sendMessage(message);
                    }
                } catch (IOException ignored) {
                    // drop dead session on next close
                }
            }
        }
    }

    public void sendToAllAdmins(String json) {
        TextMessage message = new TextMessage(json);
        for (Map.Entry<String, Set<WebSocketSession>> entry : sessions.entrySet()) {
            if (!entry.getKey().startsWith(ChatSenderType.ADMIN.name() + ":")) {
                continue;
            }
            for (WebSocketSession session : entry.getValue()) {
                if (session.isOpen()) {
                    try {
                        synchronized (session) {
                            session.sendMessage(message);
                        }
                    } catch (IOException ignored) {
                    }
                }
            }
        }
    }

    public void closeQuietly(WebSocketSession session, CloseStatus status) {
        try {
            if (session.isOpen()) {
                session.close(status);
            }
        } catch (IOException ignored) {
        }
    }
}
