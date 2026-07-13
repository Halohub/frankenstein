package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum OssProviderType {

    ALIYUN("Aliyun OSS"),
    QINIU("Qiniu Cloud");

    private final String label;

    OssProviderType(String label) {
        this.label = label;
    }
}
