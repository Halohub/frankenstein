package com.halohub.frankenstein.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class OrderCreateRequest {

    @NotBlank
    private String source;

    private List<Long> cartItemIds;

    @Valid
    private List<OrderDirectItemRequest> items;

    @NotBlank
    @Size(max = 64)
    private String receiverName;

    @NotBlank
    @Size(max = 20)
    private String receiverPhone;

    @NotBlank
    @Size(max = 512)
    private String receiverAddress;

    @Size(max = 255)
    private String remark;
}
