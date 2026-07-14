package com.halohub.frankenstein.controller.admin;

import cn.dev33.satoken.annotation.SaCheckLogin;
import com.halohub.frankenstein.common.result.Result;
import com.halohub.frankenstein.dto.ChatSendMessageRequest;
import com.halohub.frankenstein.satoken.StpAdminUtil;
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
@RequestMapping("/admin/api_v1/chat")
public class AdminChatController {

    private final ChatService chatService;

    public AdminChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping("/session/list")
    @SaCheckLogin(type = "admin")
    public Result<PageResult<ChatSessionVO>> sessions(@RequestParam(defaultValue = "1") int pageNum,
                                                      @RequestParam(defaultValue = "20") int pageSize,
                                                      @RequestParam(required = false) String status) {
        return Result.success(chatService.pageAdminSessions(pageNum, pageSize, status));
    }

    @GetMapping("/session/{id}")
    @SaCheckLogin(type = "admin")
    public Result<ChatSessionVO> sessionDetail(@PathVariable Long id) {
        return Result.success(chatService.getSessionForAdmin(id));
    }

    @GetMapping("/session/{id}/messages")
    @SaCheckLogin(type = "admin")
    public Result<PageResult<ChatMessageVO>> messages(@PathVariable Long id,
                                                      @RequestParam(defaultValue = "1") int pageNum,
                                                      @RequestParam(defaultValue = "50") int pageSize) {
        chatService.getSessionForAdmin(id);
        return Result.success(chatService.pageMessages(id, pageNum, pageSize));
    }

    @PostMapping("/session/{id}/messages")
    @SaCheckLogin(type = "admin")
    public Result<ChatMessageVO> send(@PathVariable Long id,
                                      @Valid @RequestBody ChatSendMessageRequest request) {
        return Result.success(chatService.sendByAdmin(id, StpAdminUtil.getLoginIdAsLong(), request));
    }

    @PostMapping("/session/{id}/read")
    @SaCheckLogin(type = "admin")
    public Result<Void> markRead(@PathVariable Long id) {
        chatService.markReadByAdmin(id, StpAdminUtil.getLoginIdAsLong());
        return Result.success();
    }

    @PostMapping("/session/{id}/close")
    @SaCheckLogin(type = "admin")
    public Result<ChatSessionVO> close(@PathVariable Long id) {
        return Result.success(chatService.closeSession(id, StpAdminUtil.getLoginIdAsLong()));
    }
}
