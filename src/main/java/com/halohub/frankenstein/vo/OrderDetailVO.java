package com.halohub.frankenstein.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
public class OrderDetailVO extends OrderVO {

    private List<OrderItemVO> items;
    private PaymentVO payment;
}
