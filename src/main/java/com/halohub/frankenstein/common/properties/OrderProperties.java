package com.halohub.frankenstein.common.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Data
@Component
@ConfigurationProperties(prefix = "frankenstein.order")
public class OrderProperties {

    private int payTimeoutMinutes = 30;
    private BigDecimal defaultFreightAmount = BigDecimal.ZERO;
    private String defaultCurrency = "CNY";
}
