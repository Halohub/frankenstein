package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum PaymentStatus {

    PENDING("PENDING"),
    SUCCESS("SUCCESS"),
    FAILED("FAILED"),
    CLOSED("CLOSED");

    private final String code;

    PaymentStatus(String code) {
        this.code = code;
    }

    public static PaymentStatus fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (PaymentStatus status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return null;
    }
}
