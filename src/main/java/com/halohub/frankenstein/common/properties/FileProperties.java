package com.halohub.frankenstein.common.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "frankenstein.file")
public class FileProperties {

    private int maxSizeMb = 10;
    private String allowedExtensions = "jpg,jpeg,png,gif,webp,pdf,mp4,zip,mp3,wav,ogg,m4a,aac,webm";
    private int signedUrlExpireSeconds = 3600;
    private AliyunOssProperties aliyun = new AliyunOssProperties();
    private QiniuOssProperties qiniu = new QiniuOssProperties();

    @Data
    public static class AliyunOssProperties {
        private boolean enabled;
        private String endpoint;
        private String accessKeyId;
        private String accessKeySecret;
        private String bucket;
        private String domain;
        private String pathPrefix = "frankenstein/";
        private boolean privateAccess;
    }

    @Data
    public static class QiniuOssProperties {
        private boolean enabled;
        private String accessKey;
        private String secretKey;
        private String bucket;
        private String domain;
        private String pathPrefix = "frankenstein/";
        private boolean privateAccess;
    }
}
