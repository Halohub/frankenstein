package com.halohub.frankenstein.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.halohub.frankenstein.entity.SysMember;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SysMemberMapper extends BaseMapper<SysMember> {

    @Select("SELECT r.role_code FROM sys_role r " +
            "INNER JOIN sys_member_role mr ON r.id = mr.role_id " +
            "WHERE mr.member_id = #{memberId} AND r.deleted = 0 AND r.status = 1")
    List<String> listRoleCodesByMemberId(@Param("memberId") Long memberId);

    @Select("SELECT DISTINCT p.perm_code FROM sys_permission p " +
            "INNER JOIN sys_role_permission rp ON p.id = rp.permission_id " +
            "INNER JOIN sys_member_role mr ON rp.role_id = mr.role_id " +
            "WHERE mr.member_id = #{memberId} AND p.deleted = 0 AND p.status = 1")
    List<String> listPermCodesByMemberId(@Param("memberId") Long memberId);

    @Insert("INSERT INTO sys_member_role (member_id, role_id) " +
            "SELECT #{memberId}, id FROM sys_role WHERE role_code = #{roleCode} LIMIT 1")
    int bindDefaultRole(@Param("memberId") Long memberId, @Param("roleCode") String roleCode);
}
