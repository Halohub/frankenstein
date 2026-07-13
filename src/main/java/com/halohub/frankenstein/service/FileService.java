package com.halohub.frankenstein.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.enums.OssProviderType;
import com.halohub.frankenstein.common.exception.BusinessException;
import com.halohub.frankenstein.common.properties.FileProperties;
import com.halohub.frankenstein.entity.BizFile;
import com.halohub.frankenstein.mapper.BizFileMapper;
import com.halohub.frankenstein.storage.StorageProvider;
import com.halohub.frankenstein.storage.StorageProviderFactory;
import com.halohub.frankenstein.storage.StoredObject;
import com.halohub.frankenstein.vo.FileVO;
import com.halohub.frankenstein.vo.OssConfigVO;
import com.halohub.frankenstein.vo.PageResult;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FileService {

    private static final DateTimeFormatter DATE_PATH = DateTimeFormatter.ofPattern("yyyy/MM/dd");

    private final BizFileMapper bizFileMapper;
    private final StorageProviderFactory storageProviderFactory;
    private final FileProperties fileProperties;

    public FileService(BizFileMapper bizFileMapper,
                       StorageProviderFactory storageProviderFactory,
                       FileProperties fileProperties) {
        this.bizFileMapper = bizFileMapper;
        this.storageProviderFactory = storageProviderFactory;
        this.fileProperties = fileProperties;
    }

    public FileVO upload(MultipartFile file, OssProviderType provider, String bizType) {
        validateUpload(file);
        StorageProvider storageProvider = storageProviderFactory.get(provider);
        String objectKey = buildObjectKey(provider, file.getOriginalFilename());
        StorageProvider.StorageUploadRequest request;
        try {
            request = new StorageProvider.StorageUploadRequest(
                    file.getOriginalFilename(),
                    file.getContentType(),
                    file.getSize(),
                    file.getInputStream(),
                    objectKey);
        } catch (Exception ex) {
            throw new BusinessException(CommonErrorCode.FILE_UPLOAD_FAILED);
        }
        StoredObject storedObject = storageProvider.upload(request);

        BizFile record = new BizFile();
        record.setOriginalName(file.getOriginalFilename());
        record.setObjectKey(storedObject.getObjectKey());
        record.setUrl(storedObject.getUrl());
        record.setMimeType(storedObject.getContentType());
        record.setSizeBytes(storedObject.getSize());
        record.setProvider(provider.name());
        record.setBizType(StringUtils.hasText(bizType) ? bizType : null);
        bizFileMapper.insert(record);
        return toFileVO(record);
    }

    public PageResult<FileVO> pageFiles(int pageNum,
                                        int pageSize,
                                        String provider,
                                        String bizType,
                                        String originalName) {
        Page<BizFile> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<BizFile> wrapper = new LambdaQueryWrapper<BizFile>()
                .eq(StringUtils.hasText(provider), BizFile::getProvider, provider)
                .eq(StringUtils.hasText(bizType), BizFile::getBizType, bizType)
                .like(StringUtils.hasText(originalName), BizFile::getOriginalName, originalName)
                .orderByDesc(BizFile::getId);
        Page<BizFile> result = bizFileMapper.selectPage(page, wrapper);
        List<FileVO> list = result.getRecords().stream().map(this::toFileVO).toList();
        return PageResult.of(list, result.getTotal());
    }

    public FileVO getFile(Long id) {
        BizFile record = requireFile(id);
        FileVO vo = toFileVO(record);
        vo.setUrl(resolveAccessUrl(record));
        return vo;
    }

    public String getPreviewUrl(Long id, Long expireSeconds) {
        BizFile record = requireFile(id);
        StorageProvider storageProvider = storageProviderFactory.get(OssProviderType.valueOf(record.getProvider()));
        long expire = expireSeconds != null && expireSeconds > 0
                ? expireSeconds
                : fileProperties.getSignedUrlExpireSeconds();
        return storageProvider.getSignedUrl(record.getObjectKey(), expire);
    }

    public void deleteFile(Long id) {
        BizFile record = requireFile(id);
        StorageProvider storageProvider = storageProviderFactory.get(OssProviderType.valueOf(record.getProvider()));
        storageProvider.delete(record.getObjectKey());
        bizFileMapper.deleteById(id);
    }

    public OssConfigVO getOssConfig() {
        OssConfigVO config = new OssConfigVO();
        config.setMaxSizeMb(fileProperties.getMaxSizeMb());
        config.setAllowedExtensions(parseAllowedExtensions());
        config.setSignedUrlExpireSeconds(fileProperties.getSignedUrlExpireSeconds());
        config.setProviders(Arrays.stream(OssProviderType.values())
                .map(this::buildProviderConfig)
                .toList());
        return config;
    }

    private OssConfigVO.OssProviderConfigVO buildProviderConfig(OssProviderType type) {
        StorageProvider provider = storageProviderFactory.find(type);
        boolean configured = provider != null && provider.isConfigured();
        OssConfigVO.OssProviderConfigVO vo = new OssConfigVO.OssProviderConfigVO();
        vo.setType(type.name());
        vo.setLabel(type.getLabel());
        vo.setConfigured(configured);
        if (type == OssProviderType.ALIYUN) {
            FileProperties.AliyunOssProperties aliyun = fileProperties.getAliyun();
            vo.setEnabled(aliyun.isEnabled());
            vo.setBucket(aliyun.getBucket());
            vo.setDomain(aliyun.getDomain());
            vo.setEndpoint(aliyun.getEndpoint());
            vo.setPathPrefix(aliyun.getPathPrefix());
            vo.setPrivateAccess(aliyun.isPrivateAccess());
        } else {
            FileProperties.QiniuOssProperties qiniu = fileProperties.getQiniu();
            vo.setEnabled(qiniu.isEnabled());
            vo.setBucket(qiniu.getBucket());
            vo.setDomain(qiniu.getDomain());
            vo.setPathPrefix(qiniu.getPathPrefix());
            vo.setPrivateAccess(qiniu.isPrivateAccess());
        }
        return vo;
    }

    private void validateUpload(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(CommonErrorCode.PARAM_CANNOT_BE_EMPTY);
        }
        long maxBytes = fileProperties.getMaxSizeMb() * 1024L * 1024L;
        if (file.getSize() > maxBytes) {
            throw new BusinessException(CommonErrorCode.FILE_TOO_LARGE);
        }
        String extension = extractExtension(file.getOriginalFilename());
        if (!isAllowedExtension(extension)) {
            throw new BusinessException(CommonErrorCode.FILE_TYPE_NOT_ALLOWED);
        }
    }

    private String buildObjectKey(OssProviderType provider, String originalFilename) {
        String prefix = switch (provider) {
            case ALIYUN -> normalizePrefix(fileProperties.getAliyun().getPathPrefix());
            case QINIU -> normalizePrefix(fileProperties.getQiniu().getPathPrefix());
        };
        String extension = extractExtension(originalFilename);
        return prefix + LocalDate.now().format(DATE_PATH) + "/" + UUID.randomUUID() + extension;
    }

    private String normalizePrefix(String prefix) {
        if (!StringUtils.hasText(prefix)) {
            return "";
        }
        return prefix.endsWith("/") ? prefix : prefix + "/";
    }

    private String extractExtension(String filename) {
        if (!StringUtils.hasText(filename) || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.')).toLowerCase(Locale.ROOT);
    }

    private boolean isAllowedExtension(String extension) {
        if (!StringUtils.hasText(extension)) {
            return false;
        }
        Set<String> allowed = parseAllowedExtensions().stream()
                .map(item -> item.startsWith(".") ? item : "." + item)
                .collect(Collectors.toSet());
        return allowed.contains(extension.toLowerCase(Locale.ROOT));
    }

    private List<String> parseAllowedExtensions() {
        return Arrays.stream(fileProperties.getAllowedExtensions().split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .map(item -> item.toLowerCase(Locale.ROOT))
                .toList();
    }

    private BizFile requireFile(Long id) {
        BizFile record = bizFileMapper.selectById(id);
        if (record == null) {
            throw new BusinessException(CommonErrorCode.RESOURCE_NOT_FOUND);
        }
        return record;
    }

    private String resolveAccessUrl(BizFile record) {
        StorageProvider storageProvider = storageProviderFactory.get(OssProviderType.valueOf(record.getProvider()));
        return storageProvider.getAccessUrl(record.getObjectKey());
    }

    private FileVO toFileVO(BizFile record) {
        FileVO vo = new FileVO();
        BeanUtils.copyProperties(record, vo);
        return vo;
    }
}
