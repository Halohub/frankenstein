package com.halohub.frankenstein.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.enums.PaymentStatus;
import com.halohub.frankenstein.common.exception.BusinessException;
import com.halohub.frankenstein.entity.BizOrder;
import com.halohub.frankenstein.entity.BizOrderItem;
import com.halohub.frankenstein.entity.BizPayment;
import com.halohub.frankenstein.entity.SysMember;
import com.halohub.frankenstein.mapper.BizOrderItemMapper;
import com.halohub.frankenstein.mapper.BizOrderMapper;
import com.halohub.frankenstein.mapper.BizPaymentMapper;
import com.halohub.frankenstein.mapper.SysMemberMapper;
import com.halohub.frankenstein.vo.AdminOrderDetailVO;
import com.halohub.frankenstein.vo.AdminOrderVO;
import com.halohub.frankenstein.vo.OrderItemVO;
import com.halohub.frankenstein.vo.OrderVO;
import com.halohub.frankenstein.vo.PageResult;
import com.halohub.frankenstein.vo.PaymentVO;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AdminOrderService {

    private final BizOrderMapper bizOrderMapper;
    private final BizOrderItemMapper bizOrderItemMapper;
    private final BizPaymentMapper bizPaymentMapper;
    private final SysMemberMapper sysMemberMapper;
    private final MemberOrderService memberOrderService;

    public AdminOrderService(BizOrderMapper bizOrderMapper,
                             BizOrderItemMapper bizOrderItemMapper,
                             BizPaymentMapper bizPaymentMapper,
                             SysMemberMapper sysMemberMapper,
                             MemberOrderService memberOrderService) {
        this.bizOrderMapper = bizOrderMapper;
        this.bizOrderItemMapper = bizOrderItemMapper;
        this.bizPaymentMapper = bizPaymentMapper;
        this.sysMemberMapper = sysMemberMapper;
        this.memberOrderService = memberOrderService;
    }

    public PageResult<AdminOrderVO> pageOrders(int pageNum,
                                               int pageSize,
                                               String orderNo,
                                               String status,
                                               Long memberId,
                                               String memberUsername) {
        memberOrderService.expireAllPendingOrders();

        Set<Long> memberIds = resolveMemberIds(memberId, memberUsername);
        if (memberIds != null && memberIds.isEmpty()) {
            return PageResult.of(List.of(), 0L);
        }

        Page<BizOrder> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<BizOrder> wrapper = new LambdaQueryWrapper<BizOrder>()
                .like(StringUtils.hasText(orderNo), BizOrder::getOrderNo, orderNo)
                .eq(StringUtils.hasText(status), BizOrder::getStatus, status)
                .in(memberIds != null, BizOrder::getMemberId, memberIds)
                .orderByDesc(BizOrder::getId);
        Page<BizOrder> result = bizOrderMapper.selectPage(page, wrapper);
        Map<Long, SysMember> memberMap = loadMembers(result.getRecords());
        List<AdminOrderVO> list = result.getRecords().stream()
                .map(order -> toAdminOrderVO(order, memberMap.get(order.getMemberId())))
                .toList();
        return PageResult.of(list, result.getTotal());
    }

    public AdminOrderDetailVO getOrderDetail(Long orderId) {
        memberOrderService.expireAllPendingOrders();
        BizOrder order = getOrderOrThrow(orderId);
        SysMember member = sysMemberMapper.selectById(order.getMemberId());
        return toAdminOrderDetail(order, member);
    }

    private Set<Long> resolveMemberIds(Long memberId, String memberUsername) {
        if (memberId != null) {
            return Set.of(memberId);
        }
        if (!StringUtils.hasText(memberUsername)) {
            return null;
        }
        List<SysMember> members = sysMemberMapper.selectList(new LambdaQueryWrapper<SysMember>()
                .like(SysMember::getUsername, memberUsername));
        return members.stream().map(SysMember::getId).collect(Collectors.toSet());
    }

    private Map<Long, SysMember> loadMembers(List<BizOrder> orders) {
        Set<Long> memberIds = orders.stream()
                .map(BizOrder::getMemberId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        if (memberIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return sysMemberMapper.selectBatchIds(memberIds).stream()
                .collect(Collectors.toMap(SysMember::getId, member -> member));
    }

    private BizOrder getOrderOrThrow(Long orderId) {
        BizOrder order = bizOrderMapper.selectById(orderId);
        if (order == null) {
            throw new BusinessException(CommonErrorCode.NO_CORRESPONDING_DATA);
        }
        return order;
    }

    private AdminOrderDetailVO toAdminOrderDetail(BizOrder order, SysMember member) {
        AdminOrderDetailVO detail = new AdminOrderDetailVO();
        BeanUtils.copyProperties(toAdminOrderVO(order, member), detail);
        detail.setItems(bizOrderItemMapper.listByOrderId(order.getId()).stream()
                .map(this::toOrderItemVO)
                .toList());

        List<BizPayment> payments = bizPaymentMapper.listByOrderId(order.getId());
        detail.setPayments(payments.stream().map(this::toPaymentVO).toList());
        detail.setPayment(resolvePrimaryPayment(payments));
        return detail;
    }

    private PaymentVO resolvePrimaryPayment(List<BizPayment> payments) {
        if (payments == null || payments.isEmpty()) {
            return null;
        }
        for (BizPayment payment : payments) {
            if (PaymentStatus.SUCCESS.getCode().equals(payment.getStatus())) {
                return toPaymentVO(payment);
            }
        }
        return toPaymentVO(payments.get(0));
    }

    private AdminOrderVO toAdminOrderVO(BizOrder order, SysMember member) {
        AdminOrderVO vo = new AdminOrderVO();
        BeanUtils.copyProperties(toOrderVO(order), vo);
        vo.setMemberId(order.getMemberId());
        if (member != null) {
            vo.setMemberUsername(member.getUsername());
            vo.setMemberNickname(member.getNickname());
        }
        return vo;
    }

    private OrderVO toOrderVO(BizOrder order) {
        OrderVO vo = new OrderVO();
        BeanUtils.copyProperties(order, vo);
        return vo;
    }

    private OrderItemVO toOrderItemVO(BizOrderItem item) {
        OrderItemVO vo = new OrderItemVO();
        BeanUtils.copyProperties(item, vo);
        return vo;
    }

    private PaymentVO toPaymentVO(BizPayment payment) {
        PaymentVO vo = new PaymentVO();
        BeanUtils.copyProperties(payment, vo);
        return vo;
    }
}
