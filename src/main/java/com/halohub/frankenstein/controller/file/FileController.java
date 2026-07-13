package com.halohub.frankenstein.controller.file;

import com.halohub.frankenstein.common.enums.OssProviderType;
import com.halohub.frankenstein.common.result.Result;
import com.halohub.frankenstein.service.FileService;
import com.halohub.frankenstein.vo.FileVO;
import com.halohub.frankenstein.vo.OssConfigVO;
import com.halohub.frankenstein.vo.PageResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Arrays;
import java.util.List;


@RestController
@RequestMapping("/file/api_v1")
public class FileController {

    private final FileService fileService;

    public FileController(FileService fileService) {
        this.fileService = fileService;
    }

    @GetMapping("/config")
    public Result<OssConfigVO> config() {
        return Result.success(fileService.getOssConfig());
    }

    @GetMapping("/providers")
    public Result<List<String>> providers() {
        List<String> types = Arrays.stream(OssProviderType.values())
                .map(OssProviderType::name)
                .toList();
        return Result.success(types);
    }

    @PostMapping("/upload")
    public Result<FileVO> upload(@RequestParam("file") MultipartFile file,
                               @RequestParam("provider") OssProviderType provider,
                               @RequestParam(value = "bizType", required = false) String bizType) {
        return Result.success(fileService.upload(file, provider, bizType));
    }

    @GetMapping("/list")
    public Result<PageResult<FileVO>> list(@RequestParam(defaultValue = "1") int pageNum,
                                         @RequestParam(defaultValue = "10") int pageSize,
                                         @RequestParam(required = false) String provider,
                                         @RequestParam(required = false) String bizType,
                                         @RequestParam(required = false) String originalName) {
        return Result.success(fileService.pageFiles(pageNum, pageSize, provider, bizType, originalName));
    }

    @GetMapping("/{id}")
    public Result<FileVO> detail(@PathVariable Long id) {
        return Result.success(fileService.getFile(id));
    }

    @GetMapping("/{id}/preview")
    public Result<String> preview(@PathVariable Long id,
                                  @RequestParam(required = false) Long expireSeconds) {
        return Result.success(fileService.getPreviewUrl(id, expireSeconds));
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        fileService.deleteFile(id);
        return Result.success();
    }
}
