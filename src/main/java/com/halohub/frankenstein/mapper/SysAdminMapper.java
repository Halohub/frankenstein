package com.halohub.frankenstein.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.halohub.frankenstein.entity.SysAdmin;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SysAdminMapper extends BaseMapper<SysAdmin> {

    @Select("SELECT r.role_code FROM sys_role r " +
            "INNER JOIN sys_admin_role ar ON r.id = ar.role_id " +
            "WHERE ar.admin_id = #{adminId} AND r.deleted = 0 AND r.status = 1")
    List<String> listRoleCodesByAdminId(@Param("adminId") Long adminId);

    @Select("SELECT DISTINCT p.perm_code FROM sys_permission p " +
            "INNER JOIN sys_role_permission rp ON p.id = rp.permission_id " +
            "INNER JOIN sys_admin_role ar ON rp.role_id = ar.role_id " +
            "WHERE ar.admin_id = #{adminId} AND p.deleted = 0 AND p.status = 1")
    List<String> listPermCodesByAdminId(@Param("adminId") Long adminId);
}
