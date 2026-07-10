package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PaymentCallbackRequest {

    @NotBlank
    private String paymentNo;
}
