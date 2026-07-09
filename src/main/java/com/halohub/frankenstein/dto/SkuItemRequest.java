package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class SkuItemRequest {

    private Long id;

    @NotBlank
    @Size(max = 64)
    private String skuCode;

    private String specJson;

    @NotNull
    @DecimalMin("0.00")
    private BigDecimal price;

    @NotNull
    @Min(0)
    private Integer stock;

    private String image;

    @NotNull
    private Integer status;
}
