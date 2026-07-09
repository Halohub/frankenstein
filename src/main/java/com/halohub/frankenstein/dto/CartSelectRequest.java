package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class CartSelectRequest {

    @NotEmpty
    private List<Long> itemIds;

    @NotNull
    private Boolean selected;
}
