package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class CartListVO {

    private List<CartItemVO> items;
    private Integer totalCount;
    private Integer selectedCount;
    private BigDecimal selectedAmount;
}
