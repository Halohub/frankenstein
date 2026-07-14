package com.halohub.frankenstein.chat;

import com.alibaba.fastjson2.JSON;
import com.halohub.frankenstein.common.enums.ChatSenderType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class ChatPushService implements MessageListener {

    public static final String CHANNEL = "frankenstein:chat:push";

    private final StringRedisTemplate stringRedisTemplate;
    private final ChatSessionHub chatSessionHub;

    public ChatPushService(StringRedisTemplate stringRedisTemplate, ChatSessionHub chatSessionHub) {
        this.stringRedisTemplate = stringRedisTemplate;
        this.chatSessionHub = chatSessionHub;
    }

    public void publish(ChatPushEvent event) {
        stringRedisTemplate.convertAndSend(CHANNEL, JSON.toJSONString(event));
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String body = new String(message.getBody());
        try {
            ChatPushEvent event = JSON.parseObject(body, ChatPushEvent.class);
            if (event == null || event.getTargetType() == null) {
                return;
            }
            String json = JSON.toJSONString(event);
            if ("ADMIN_BROADCAST".equals(event.getTargetType())) {
                chatSessionHub.sendToAllAdmins(json);
                return;
            }
            ChatSenderType type = ChatSenderType.valueOf(event.getTargetType());
            chatSessionHub.sendTo(type, event.getTargetId(), json);
        } catch (Exception ex) {
            log.warn("Failed to handle chat push: {}", body, ex);
        }
    }
}
