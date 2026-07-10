package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class OrderItemVO {

    private Long id;
    private Long spuId;
    private Long skuId;
    private String productTitle;
    private String skuCode;
    private String skuSpec;
    private BigDecimal unitPrice;
    private Integer quantity;
    private BigDecimal subtotal;
}
