package com.halohub.frankenstein.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatSessionVO {

    private Long id;
    private Long memberId;
    private String memberUsername;
    private String memberNickname;
    private Long adminId;
    private String adminUsername;
    private String adminNickname;
    private String status;
    private String lastMessage;
    private String lastMsgType;
    private LocalDateTime lastMessageTime;
    private Integer memberUnread;
    private Integer adminUnread;
    private LocalDateTime createTime;
}
