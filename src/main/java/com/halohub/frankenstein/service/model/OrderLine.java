package com.halohub.frankenstein.service.model;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
public class OrderLine {

    private Long cartItemId;
    private Long skuId;
    private Long spuId;
    private Integer quantity;
    private BigDecimal unitPrice;
    private String productTitle;
    private String skuCode;
    private String skuSpec;
    private BigDecimal subtotal;
}
