package com.halohub.frankenstein.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatMessageVO {

    private Long id;
    private Long sessionId;
    private String senderType;
    private Long senderId;
    private String msgType;
    private String content;
    private Integer readFlag;
    private LocalDateTime createTime;
}
