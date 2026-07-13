package com.halohub.frankenstein.storage.impl;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.GeneratePresignedUrlRequest;
import com.aliyun.oss.model.ObjectMetadata;
import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.enums.OssProviderType;
import com.halohub.frankenstein.common.exception.BusinessException;
import com.halohub.frankenstein.common.properties.FileProperties;
import com.halohub.frankenstein.storage.StorageProvider;
import com.halohub.frankenstein.storage.StoredObject;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.net.URL;
import java.util.Date;

@Component
@Slf4j
public class AliyunOssStorageProvider implements StorageProvider {

    private final FileProperties fileProperties;
    private volatile OSS ossClient;

    public AliyunOssStorageProvider(FileProperties fileProperties) {
        this.fileProperties = fileProperties;
    }

    @Override
    public OssProviderType type() {
        return OssProviderType.ALIYUN;
    }

    @Override
    public boolean isConfigured() {
        FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
        return config.isEnabled()
                && StringUtils.hasText(config.getEndpoint())
                && StringUtils.hasText(config.getAccessKeyId())
                && StringUtils.hasText(config.getAccessKeySecret())
                && StringUtils.hasText(config.getBucket());
    }

    @Override
    public StoredObject upload(StorageUploadRequest request) {
        FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
        OSS client = client();
        try {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(request.size());
            if (StringUtils.hasText(request.contentType())) {
                metadata.setContentType(request.contentType());
            }
            client.putObject(config.getBucket(), request.objectKey(), request.inputStream(), metadata);
            return StoredObject.builder()
                    .objectKey(request.objectKey())
                    .url(getAccessUrl(request.objectKey()))
                    .contentType(request.contentType())
                    .size(request.size())
                    .build();
        } catch (Exception ex) {
            log.error("Aliyun OSS upload failed, key={}", request.objectKey(), ex);
            throw new BusinessException(CommonErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    @Override
    public void delete(String objectKey) {
        FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
        try {
            client().deleteObject(config.getBucket(), objectKey);
        } catch (Exception ex) {
            log.error("Aliyun OSS delete failed, key={}", objectKey, ex);
            throw new BusinessException(CommonErrorCode.OPERATION_FAILED);
        }
    }

    @Override
    public String getAccessUrl(String objectKey) {
        FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
        if (config.isPrivateAccess()) {
            return getSignedUrl(objectKey, fileProperties.getSignedUrlExpireSeconds());
        }
        String domain = resolveDomain(config);
        return joinUrl(domain, objectKey);
    }

    @Override
    public String getSignedUrl(String objectKey, long expireSeconds) {
        FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
        Date expiration = new Date(System.currentTimeMillis() + expireSeconds * 1000L);
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest(
                config.getBucket(), objectKey);
        request.setExpiration(expiration);
        URL url = client().generatePresignedUrl(request);
        return url.toString();
    }

    private OSS client() {
        if (ossClient == null) {
            synchronized (this) {
                if (ossClient == null) {
                    FileProperties.AliyunOssProperties config = fileProperties.getAliyun();
                    ossClient = new OSSClientBuilder().build(
                            config.getEndpoint(),
                            config.getAccessKeyId(),
                            config.getAccessKeySecret());
                }
            }
        }
        return ossClient;
    }

    private String resolveDomain(FileProperties.AliyunOssProperties config) {
        if (StringUtils.hasText(config.getDomain())) {
            return trimTrailingSlash(config.getDomain());
        }
        return "https://" + config.getBucket() + "." + config.getEndpoint();
    }

    private String joinUrl(String domain, String objectKey) {
        return domain + "/" + objectKey;
    }

    private String trimTrailingSlash(String value) {
        if (value.endsWith("/")) {
            return value.substring(0, value.length() - 1);
        }
        return value;
    }

    @PreDestroy
    public void destroy() {
        if (ossClient != null) {
            ossClient.shutdown();
        }
    }
}
