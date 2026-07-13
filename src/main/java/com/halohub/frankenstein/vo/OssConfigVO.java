package com.halohub.frankenstein.vo;

import lombok.Data;

import java.util.List;

@Data
public class OssConfigVO {

    private int maxSizeMb;
    private List<String> allowedExtensions;
    private int signedUrlExpireSeconds;
    private List<OssProviderConfigVO> providers;

    @Data
    public static class OssProviderConfigVO {
        private String type;
        private String label;
        private boolean enabled;
        private boolean configured;
        private String bucket;
        private String domain;
        private String endpoint;
        private String pathPrefix;
        private boolean privateAccess;
    }
}
