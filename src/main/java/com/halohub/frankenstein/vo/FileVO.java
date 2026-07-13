package com.halohub.frankenstein.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class FileVO {

    private Long id;
    private String originalName;
    private String objectKey;
    private String url;
    private String mimeType;
    private Long sizeBytes;
    private String provider;
    private String bizType;
    private LocalDateTime createTime;
}
