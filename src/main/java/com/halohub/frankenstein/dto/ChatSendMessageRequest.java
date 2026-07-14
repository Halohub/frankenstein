package com.halohub.frankenstein.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ChatSendMessageRequest {

    @NotBlank
    @Pattern(regexp = "TEXT|IMAGE")
    private String msgType;

    @NotBlank
    @Size(max = 2048)
    private String content;
}
