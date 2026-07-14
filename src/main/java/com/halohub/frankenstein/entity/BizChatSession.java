package com.halohub.frankenstein.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("biz_chat_session")
public class BizChatSession {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long memberId;
    private Long adminId;
    private String status;
    private String lastMessage;
    private String lastMsgType;
    private LocalDateTime lastMessageTime;
    private Integer memberUnread;
    private Integer adminUnread;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
