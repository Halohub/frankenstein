package com.halohub.frankenstein.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class SpuUpdateRequest {

    @NotNull
    private Long categoryId;

    @NotBlank
    @Size(max = 128)
    private String title;

    @Size(max = 255)
    private String subtitle;

    private String description;

    private String mainImage;

    @NotNull
    private Integer status;

    @NotEmpty
    @Valid
    private List<SkuItemRequest> skus;
}
