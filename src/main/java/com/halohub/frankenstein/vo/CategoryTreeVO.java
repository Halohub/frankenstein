package com.halohub.frankenstein.vo;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class CategoryTreeVO {

    private Long id;
    private Long parentId;
    private String name;
    private String icon;
    private Integer sort;
    private Integer level;
    private Integer status;
    private List<CategoryTreeVO> children = new ArrayList<>();
}
