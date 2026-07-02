package com.halohub.frankenstein.pojo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoContextBo {

    private Long userId;
    private String loginType;
    private String username;
}
