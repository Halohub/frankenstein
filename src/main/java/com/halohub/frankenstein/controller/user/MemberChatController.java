package com.halohub.frankenstein.controller.user;

import cn.dev33.satoken.annotation.SaCheckLogin;
import com.halohub.frankenstein.common.result.Result;
import com.halohub.frankenstein.dto.ChatSendMessageRequest;
import com.halohub.frankenstein.satoken.StpMemberUtil;
import com.halohub.frankenstein.service.ChatService;
import com.halohub.frankenstein.vo.ChatMessageVO;
import com.halohub.frankenstein.vo.ChatSessionVO;
import com.halohub.frankenstein.vo.PageResult;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user/api_v1/chat")
public class MemberChatController {

    private final ChatService chatService;

    public MemberChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/session")
    @SaCheckLogin(type = "user")
    public Result<ChatSessionVO> openSession() {
        return Result.success(chatService.openOrGetMemberSession(StpMemberUtil.getLoginIdAsLong()));
    }

    @GetMapping("/session/list")
    @SaCheckLogin(type = "user")
    public Result<PageResult<ChatSessionVO>> sessions(@RequestParam(defaultValue = "1") int pageNum,
                                                      @RequestParam(defaultValue = "20") int pageSize) {
        return Result.success(chatService.pageMemberSessions(
                StpMemberUtil.getLoginIdAsLong(), pageNum, pageSize));
    }

    @GetMapping("/session/{id}")
    @SaCheckLogin(type = "user")
    public Result<ChatSessionVO> sessionDetail(@PathVariable Long id) {
        return Result.success(chatService.getSessionForMember(id, StpMemberUtil.getLoginIdAsLong()));
    }

    @GetMapping("/session/{id}/messages")
    @SaCheckLogin(type = "user")
    public Result<PageResult<ChatMessageVO>> messages(@PathVariable Long id,
                                                      @RequestParam(defaultValue = "1") int pageNum,
                                                      @RequestParam(defaultValue = "50") int pageSize) {
        chatService.getSessionForMember(id, StpMemberUtil.getLoginIdAsLong());
        return Result.success(chatService.pageMessages(id, pageNum, pageSize));
    }

    @PostMapping("/session/{id}/messages")
    @SaCheckLogin(type = "user")
    public Result<ChatMessageVO> send(@PathVariable Long id,
                                      @Valid @RequestBody ChatSendMessageRequest request) {
        return Result.success(chatService.sendByMember(id, StpMemberUtil.getLoginIdAsLong(), request));
    }

    @PostMapping("/session/{id}/read")
    @SaCheckLogin(type = "user")
    public Result<Void> markRead(@PathVariable Long id) {
        chatService.markReadByMember(id, StpMemberUtil.getLoginIdAsLong());
        return Result.success();
    }
}
