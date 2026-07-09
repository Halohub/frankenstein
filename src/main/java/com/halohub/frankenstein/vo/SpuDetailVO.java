package com.halohub.frankenstein.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
public class SpuDetailVO extends SpuVO {

    private List<SkuVO> skus;
}
