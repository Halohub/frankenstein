package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class CartItemVO {

    private Long id;
    private Long skuId;
    private Integer quantity;
    private Boolean selected;
    private Boolean valid;

    private Long spuId;
    private String spuTitle;
    private String mainImage;
    private String skuCode;
    private String specJson;
    private BigDecimal price;
    private Integer stock;
    private String skuImage;
    private BigDecimal subtotal;
}
