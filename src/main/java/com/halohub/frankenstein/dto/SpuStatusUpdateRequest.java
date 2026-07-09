package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SpuStatusUpdateRequest {

    @NotNull
    private Integer status;
}
