package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class SkuVO {

    private Long id;
    private Long spuId;
    private String skuCode;
    private String specJson;
    private BigDecimal price;
    private Integer stock;
    private String image;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
