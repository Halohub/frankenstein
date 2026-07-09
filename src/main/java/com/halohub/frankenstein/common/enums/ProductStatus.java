package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum ProductStatus {

    OFF(0),
    ON(1);

    private final int code;

    ProductStatus(int code) {
        this.code = code;
    }

    public static ProductStatus fromCode(Integer code) {
        if (code == null) {
            return null;
        }
        for (ProductStatus status : values()) {
            if (status.code == code) {
                return status;
            }
        }
        return null;
    }
}
