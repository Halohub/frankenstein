package com.halohub.frankenstein.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatPushEvent {

    /** MESSAGE | READ | SESSION_UPDATE */
    private String event;
    private Long sessionId;
    /** MEMBER | ADMIN | ADMIN_BROADCAST */
    private String targetType;
    private Long targetId;
    private Object payload;
}
