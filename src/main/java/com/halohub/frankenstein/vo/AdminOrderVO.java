package com.halohub.frankenstein.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
public class AdminOrderVO extends OrderVO {

    private Long memberId;
    private String memberUsername;
    private String memberNickname;
}
