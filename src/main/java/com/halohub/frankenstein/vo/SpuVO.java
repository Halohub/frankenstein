package com.halohub.frankenstein.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class SpuVO {

    private Long id;
    private Long categoryId;
    private String categoryName;
    private String title;
    private String subtitle;
    private String description;
    private String mainImage;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
