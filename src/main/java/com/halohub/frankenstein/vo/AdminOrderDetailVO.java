package com.halohub.frankenstein.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
public class AdminOrderDetailVO extends AdminOrderVO {

    private List<OrderItemVO> items;
    private PaymentVO payment;
    private List<PaymentVO> payments;
}
