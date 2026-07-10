package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum OrderSource {

    CART("CART"),
    DIRECT("DIRECT");

    private final String code;

    OrderSource(String code) {
        this.code = code;
    }

    public static OrderSource fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (OrderSource source : values()) {
            if (source.code.equalsIgnoreCase(code)) {
                return source;
            }
        }
        return null;
    }
}
