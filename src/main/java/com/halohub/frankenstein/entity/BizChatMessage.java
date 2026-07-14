package com.halohub.frankenstein.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("biz_chat_message")
public class BizChatMessage {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long sessionId;
    private String senderType;
    private Long senderId;
    private String msgType;
    private String content;
    private Integer readFlag;
    private LocalDateTime createTime;
}
