package com.halohub.frankenstein.common.enums;

import lombok.Getter;

@Getter
public enum PaymentChannel {

    MOCK("MOCK"),
    ALIPAY("ALIPAY"),
    WXPAY("WXPAY"),
    STRIPE("STRIPE");

    private final String code;

    PaymentChannel(String code) {
        this.code = code;
    }

    public static PaymentChannel fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (PaymentChannel channel : values()) {
            if (channel.code.equalsIgnoreCase(code)) {
                return channel;
            }
        }
        return null;
    }
}
