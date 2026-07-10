package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum OrderStatus {

    PENDING_PAY("PENDING_PAY"),
    PAID("PAID"),
    SHIPPED("SHIPPED"),
    COMPLETED("COMPLETED"),
    CANCELLED("CANCELLED");

    private final String code;

    OrderStatus(String code) {
        this.code = code;
    }

    public static OrderStatus fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (OrderStatus status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return null;
    }
}
