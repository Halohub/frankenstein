package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PaymentVO {

    private Long id;
    private String paymentNo;
    private Long orderId;
    private String orderNo;
    private String channel;
    private BigDecimal amount;
    private String currency;
    private String status;
    private String thirdPartyNo;
    private String clientPayload;
    private LocalDateTime payTime;
    private LocalDateTime expireTime;
    private LocalDateTime createTime;
}
