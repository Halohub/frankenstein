package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CategoryCreateRequest {

    private Long parentId;

    @NotBlank
    @Size(max = 64)
    private String name;

    private String icon;

    private Integer sort;

    @NotNull
    private Integer status;
}
