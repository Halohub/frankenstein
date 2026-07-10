package com.halohub.frankenstein.controller.admin;

import cn.dev33.satoken.annotation.SaCheckLogin;
import cn.dev33.satoken.annotation.SaCheckPermission;
import com.halohub.frankenstein.common.result.Result;
import com.halohub.frankenstein.service.AdminOrderService;
import com.halohub.frankenstein.vo.AdminOrderDetailVO;
import com.halohub.frankenstein.vo.AdminOrderVO;
import com.halohub.frankenstein.vo.PageResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/api_v1/order")
public class AdminOrderController {

    private final AdminOrderService adminOrderService;

    public AdminOrderController(AdminOrderService adminOrderService) {
        this.adminOrderService = adminOrderService;
    }

    @GetMapping("/list")
    @SaCheckLogin(type = "admin")
    @SaCheckPermission(value = "admin:order:query", type = "admin")
    public Result<PageResult<AdminOrderVO>> pageOrders(@RequestParam(defaultValue = "1") int pageNum,
                                                       @RequestParam(defaultValue = "10") int pageSize,
                                                       @RequestParam(required = false) String orderNo,
                                                       @RequestParam(required = false) String status,
                                                       @RequestParam(required = false) Long memberId,
                                                       @RequestParam(required = false) String memberUsername) {
        return Result.success(adminOrderService.pageOrders(
                pageNum, pageSize, orderNo, status, memberId, memberUsername));
    }

    @GetMapping("/{id}")
    @SaCheckLogin(type = "admin")
    @SaCheckPermission(value = "admin:order:detail", type = "admin")
    public Result<AdminOrderDetailVO> orderDetail(@PathVariable Long id) {
        return Result.success(adminOrderService.getOrderDetail(id));
    }
}
