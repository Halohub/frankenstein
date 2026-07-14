package com.halohub.frankenstein.config;

import com.halohub.frankenstein.chat.ChatPushService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;

@Configuration
public class ChatRedisConfiguration {

    @Bean
    public RedisMessageListenerContainer chatRedisMessageListenerContainer(
            RedisConnectionFactory connectionFactory,
            ChatPushService chatPushService) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.addMessageListener(chatPushService, new ChannelTopic(ChatPushService.CHANNEL));
        return container;
    }
}
