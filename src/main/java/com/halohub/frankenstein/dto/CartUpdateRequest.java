package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CartUpdateRequest {

    @NotNull
    @Min(1)
    private Integer quantity;
}
