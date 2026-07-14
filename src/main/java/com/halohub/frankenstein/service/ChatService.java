package com.halohub.frankenstein.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.halohub.frankenstein.chat.ChatPushEvent;
import com.halohub.frankenstein.chat.ChatPushService;
import com.halohub.frankenstein.common.enums.ChatMsgType;
import com.halohub.frankenstein.common.enums.ChatSenderType;
import com.halohub.frankenstein.common.enums.ChatSessionStatus;
import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.exception.BusinessException;
import com.halohub.frankenstein.dto.ChatSendMessageRequest;
import com.halohub.frankenstein.entity.BizChatMessage;
import com.halohub.frankenstein.entity.BizChatSession;
import com.halohub.frankenstein.entity.SysAdmin;
import com.halohub.frankenstein.entity.SysMember;
import com.halohub.frankenstein.mapper.BizChatMessageMapper;
import com.halohub.frankenstein.mapper.BizChatSessionMapper;
import com.halohub.frankenstein.mapper.SysAdminMapper;
import com.halohub.frankenstein.mapper.SysMemberMapper;
import com.halohub.frankenstein.vo.ChatMessageVO;
import com.halohub.frankenstein.vo.ChatSessionVO;
import com.halohub.frankenstein.vo.PageResult;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class ChatService {

    private final BizChatSessionMapper sessionMapper;
    private final BizChatMessageMapper messageMapper;
    private final SysMemberMapper sysMemberMapper;
    private final SysAdminMapper sysAdminMapper;
    private final ChatPushService chatPushService;

    public ChatService(BizChatSessionMapper sessionMapper,
                       BizChatMessageMapper messageMapper,
                       SysMemberMapper sysMemberMapper,
                       SysAdminMapper sysAdminMapper,
                       ChatPushService chatPushService) {
        this.sessionMapper = sessionMapper;
        this.messageMapper = messageMapper;
        this.sysMemberMapper = sysMemberMapper;
        this.sysAdminMapper = sysAdminMapper;
        this.chatPushService = chatPushService;
    }

    @Transactional
    public ChatSessionVO openOrGetMemberSession(Long memberId) {
        BizChatSession open = sessionMapper.selectOne(new LambdaQueryWrapper<BizChatSession>()
                .eq(BizChatSession::getMemberId, memberId)
                .eq(BizChatSession::getStatus, ChatSessionStatus.OPEN.name())
                .orderByDesc(BizChatSession::getId)
                .last("LIMIT 1"));
        if (open != null) {
            return toSessionVO(open);
        }
        BizChatSession session = new BizChatSession();
        session.setMemberId(memberId);
        session.setStatus(ChatSessionStatus.OPEN.name());
        session.setMemberUnread(0);
        session.setAdminUnread(0);
        sessionMapper.insert(session);

        ChatSessionVO vo = toSessionVO(session);
        chatPushService.publish(ChatPushEvent.builder()
                .event("SESSION_UPDATE")
                .sessionId(session.getId())
                .targetType("ADMIN_BROADCAST")
                .targetId(0L)
                .payload(vo)
                .build());
        return vo;
    }

    public PageResult<ChatSessionVO> pageMemberSessions(Long memberId, int pageNum, int pageSize) {
        Page<BizChatSession> page = sessionMapper.selectPage(new Page<>(pageNum, pageSize),
                new LambdaQueryWrapper<BizChatSession>()
                        .eq(BizChatSession::getMemberId, memberId)
                        .orderByDesc(BizChatSession::getLastMessageTime)
                        .orderByDesc(BizChatSession::getId));
        return PageResult.of(page.getRecords().stream().map(this::toSessionVO).toList(), page.getTotal());
    }

    public PageResult<ChatSessionVO> pageAdminSessions(int pageNum, int pageSize, String status) {
        Page<BizChatSession> page = sessionMapper.selectPage(new Page<>(pageNum, pageSize),
                new LambdaQueryWrapper<BizChatSession>()
                        .eq(StringUtils.hasText(status), BizChatSession::getStatus, status)
                        .orderByDesc(BizChatSession::getLastMessageTime)
                        .orderByDesc(BizChatSession::getId));
        return PageResult.of(page.getRecords().stream().map(this::toSessionVO).toList(), page.getTotal());
    }

    public ChatSessionVO getSessionForMember(Long sessionId, Long memberId) {
        BizChatSession session = requireSession(sessionId);
        if (!Objects.equals(session.getMemberId(), memberId)) {
            throw new BusinessException(CommonErrorCode.UNAUTHORIZED_OPERATION);
        }
        return toSessionVO(session);
    }

    public ChatSessionVO getSessionForAdmin(Long sessionId) {
        return toSessionVO(requireSession(sessionId));
    }

    public PageResult<ChatMessageVO> pageMessages(Long sessionId, int pageNum, int pageSize) {
        requireSession(sessionId);
        Page<BizChatMessage> page = messageMapper.selectPage(new Page<>(pageNum, pageSize),
                new LambdaQueryWrapper<BizChatMessage>()
                        .eq(BizChatMessage::getSessionId, sessionId)
                        .orderByDesc(BizChatMessage::getId));
        List<ChatMessageVO> list = page.getRecords().stream().map(this::toMessageVO).toList();
        return PageResult.of(list, page.getTotal());
    }

    @Transactional
    public ChatMessageVO sendByMember(Long sessionId, Long memberId, ChatSendMessageRequest request) {
        BizChatSession session = requireSession(sessionId);
        if (!Objects.equals(session.getMemberId(), memberId)) {
            throw new BusinessException(CommonErrorCode.UNAUTHORIZED_OPERATION);
        }
        if (!ChatSessionStatus.OPEN.name().equals(session.getStatus())) {
            throw new BusinessException(CommonErrorCode.STATUS_ERROR);
        }
        return persistAndPush(session, ChatSenderType.MEMBER, memberId, request);
    }

    @Transactional
    public ChatMessageVO sendByAdmin(Long sessionId, Long adminId, ChatSendMessageRequest request) {
        BizChatSession session = requireSession(sessionId);
        if (!ChatSessionStatus.OPEN.name().equals(session.getStatus())) {
            throw new BusinessException(CommonErrorCode.STATUS_ERROR);
        }
        if (session.getAdminId() == null) {
            session.setAdminId(adminId);
        }
        return persistAndPush(session, ChatSenderType.ADMIN, adminId, request);
    }

    @Transactional
    public void markReadByMember(Long sessionId, Long memberId) {
        BizChatSession session = requireSession(sessionId);
        if (!Objects.equals(session.getMemberId(), memberId)) {
            throw new BusinessException(CommonErrorCode.UNAUTHORIZED_OPERATION);
        }
        messageMapper.update(null, new LambdaUpdateWrapper<BizChatMessage>()
                .eq(BizChatMessage::getSessionId, sessionId)
                .eq(BizChatMessage::getSenderType, ChatSenderType.ADMIN.name())
                .eq(BizChatMessage::getReadFlag, 0)
                .set(BizChatMessage::getReadFlag, 1));
        session.setMemberUnread(0);
        sessionMapper.updateById(session);
        if (session.getAdminId() != null) {
            chatPushService.publish(ChatPushEvent.builder()
                    .event("READ")
                    .sessionId(sessionId)
                    .targetType(ChatSenderType.ADMIN.name())
                    .targetId(session.getAdminId())
                    .payload(Map.of("sessionId", sessionId, "reader", ChatSenderType.MEMBER.name()))
                    .build());
        }
    }

    @Transactional
    public void markReadByAdmin(Long sessionId, Long adminId) {
        BizChatSession session = requireSession(sessionId);
        messageMapper.update(null, new LambdaUpdateWrapper<BizChatMessage>()
                .eq(BizChatMessage::getSessionId, sessionId)
                .eq(BizChatMessage::getSenderType, ChatSenderType.MEMBER.name())
                .eq(BizChatMessage::getReadFlag, 0)
                .set(BizChatMessage::getReadFlag, 1));
        session.setAdminUnread(0);
        if (session.getAdminId() == null) {
            session.setAdminId(adminId);
        }
        sessionMapper.updateById(session);
        chatPushService.publish(ChatPushEvent.builder()
                .event("READ")
                .sessionId(sessionId)
                .targetType(ChatSenderType.MEMBER.name())
                .targetId(session.getMemberId())
                .payload(Map.of("sessionId", sessionId, "reader", ChatSenderType.ADMIN.name()))
                .build());
    }

    @Transactional
    public ChatSessionVO closeSession(Long sessionId, Long adminId) {
        BizChatSession session = requireSession(sessionId);
        session.setStatus(ChatSessionStatus.CLOSED.name());
        if (session.getAdminId() == null) {
            session.setAdminId(adminId);
        }
        sessionMapper.updateById(session);
        ChatSessionVO vo = toSessionVO(session);
        chatPushService.publish(ChatPushEvent.builder()
                .event("SESSION_UPDATE")
                .sessionId(sessionId)
                .targetType(ChatSenderType.MEMBER.name())
                .targetId(session.getMemberId())
                .payload(vo)
                .build());
        chatPushService.publish(ChatPushEvent.builder()
                .event("SESSION_UPDATE")
                .sessionId(sessionId)
                .targetType("ADMIN_BROADCAST")
                .targetId(0L)
                .payload(vo)
                .build());
        return vo;
    }

    private ChatMessageVO persistAndPush(BizChatSession session,
                                         ChatSenderType senderType,
                                         Long senderId,
                                         ChatSendMessageRequest request) {
        ChatMsgType msgType;
        try {
            msgType = ChatMsgType.valueOf(request.getMsgType());
        } catch (Exception ex) {
            throw new BusinessException(CommonErrorCode.PARAM_VALIDATION_FAILED);
        }
        BizChatMessage message = new BizChatMessage();
        message.setSessionId(session.getId());
        message.setSenderType(senderType.name());
        message.setSenderId(senderId);
        message.setMsgType(msgType.name());
        message.setContent(request.getContent().trim());
        message.setReadFlag(0);
        messageMapper.insert(message);

        String preview = msgType == ChatMsgType.IMAGE ? "[图片]" : message.getContent();
        if (preview.length() > 200) {
            preview = preview.substring(0, 200);
        }
        session.setLastMessage(preview);
        session.setLastMsgType(msgType.name());
        session.setLastMessageTime(LocalDateTime.now());
        if (senderType == ChatSenderType.MEMBER) {
            session.setAdminUnread((session.getAdminUnread() == null ? 0 : session.getAdminUnread()) + 1);
        } else {
            session.setMemberUnread((session.getMemberUnread() == null ? 0 : session.getMemberUnread()) + 1);
        }
        sessionMapper.updateById(session);

        ChatMessageVO messageVO = toMessageVO(message);
        if (senderType == ChatSenderType.MEMBER) {
            if (session.getAdminId() != null) {
                chatPushService.publish(ChatPushEvent.builder()
                        .event("MESSAGE")
                        .sessionId(session.getId())
                        .targetType(ChatSenderType.ADMIN.name())
                        .targetId(session.getAdminId())
                        .payload(messageVO)
                        .build());
            } else {
                chatPushService.publish(ChatPushEvent.builder()
                        .event("MESSAGE")
                        .sessionId(session.getId())
                        .targetType("ADMIN_BROADCAST")
                        .targetId(0L)
                        .payload(messageVO)
                        .build());
            }
        } else {
            chatPushService.publish(ChatPushEvent.builder()
                    .event("MESSAGE")
                    .sessionId(session.getId())
                    .targetType(ChatSenderType.MEMBER.name())
                    .targetId(session.getMemberId())
                    .payload(messageVO)
                    .build());
        }
        return messageVO;
    }

    private BizChatSession requireSession(Long sessionId) {
        BizChatSession session = sessionMapper.selectById(sessionId);
        if (session == null) {
            throw new BusinessException(CommonErrorCode.RESOURCE_NOT_FOUND);
        }
        return session;
    }

    private ChatSessionVO toSessionVO(BizChatSession session) {
        ChatSessionVO vo = new ChatSessionVO();
        BeanUtils.copyProperties(session, vo);
        SysMember member = sysMemberMapper.selectById(session.getMemberId());
        if (member != null) {
            vo.setMemberUsername(member.getUsername());
            vo.setMemberNickname(member.getNickname());
        }
        if (session.getAdminId() != null) {
            SysAdmin admin = sysAdminMapper.selectById(session.getAdminId());
            if (admin != null) {
                vo.setAdminUsername(admin.getUsername());
                vo.setAdminNickname(admin.getNickname());
            }
        }
        return vo;
    }

    private ChatMessageVO toMessageVO(BizChatMessage message) {
        ChatMessageVO vo = new ChatMessageVO();
        BeanUtils.copyProperties(message, vo);
        return vo;
    }
}
