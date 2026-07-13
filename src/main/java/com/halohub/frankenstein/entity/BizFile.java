package com.halohub.frankenstein.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("biz_file")
public class BizFile {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String originalName;
    private String objectKey;
    private String url;
    private String mimeType;
    private Long sizeBytes;
    private String provider;
    private String bizType;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    @TableLogic
    private Integer deleted;
}
