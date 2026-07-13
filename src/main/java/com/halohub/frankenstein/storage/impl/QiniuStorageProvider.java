package com.halohub.frankenstein.storage.impl;

import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.enums.OssProviderType;
import com.halohub.frankenstein.common.exception.BusinessException;
import com.halohub.frankenstein.common.properties.FileProperties;
import com.halohub.frankenstein.storage.StorageProvider;
import com.halohub.frankenstein.storage.StoredObject;
import com.qiniu.http.Response;
import com.qiniu.storage.BucketManager;
import com.qiniu.storage.Configuration;
import com.qiniu.storage.Region;
import com.qiniu.storage.UploadManager;
import com.qiniu.util.Auth;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
@Slf4j
public class QiniuStorageProvider implements StorageProvider {

    private final FileProperties fileProperties;

    public QiniuStorageProvider(FileProperties fileProperties) {
        this.fileProperties = fileProperties;
    }

    @Override
    public OssProviderType type() {
        return OssProviderType.QINIU;
    }

    @Override
    public boolean isConfigured() {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        return config.isEnabled()
                && StringUtils.hasText(config.getAccessKey())
                && StringUtils.hasText(config.getSecretKey())
                && StringUtils.hasText(config.getBucket())
                && StringUtils.hasText(config.getDomain());
    }

    @Override
    public StoredObject upload(StorageUploadRequest request) {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        try {
            Auth auth = auth();
            String upToken = auth.uploadToken(config.getBucket());
            UploadManager uploadManager = new UploadManager(configuration());
            Response response = uploadManager.put(
                    request.inputStream(),
                    request.objectKey(),
                    upToken,
                    null,
                    request.contentType());
            if (!response.isOK()) {
                throw new BusinessException(CommonErrorCode.FILE_UPLOAD_FAILED, response.bodyString());
            }
            return StoredObject.builder()
                    .objectKey(request.objectKey())
                    .url(getAccessUrl(request.objectKey()))
                    .contentType(request.contentType())
                    .size(request.size())
                    .build();
        } catch (BusinessException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Qiniu upload failed, key={}", request.objectKey(), ex);
            throw new BusinessException(CommonErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    @Override
    public void delete(String objectKey) {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        try {
            BucketManager bucketManager = new BucketManager(auth(), configuration());
            Response response = bucketManager.delete(config.getBucket(), objectKey);
            if (!response.isOK()) {
                throw new BusinessException(CommonErrorCode.OPERATION_FAILED, response.bodyString());
            }
        } catch (BusinessException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Qiniu delete failed, key={}", objectKey, ex);
            throw new BusinessException(CommonErrorCode.OPERATION_FAILED);
        }
    }

    @Override
    public String getAccessUrl(String objectKey) {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        if (config.isPrivateAccess()) {
            return getSignedUrl(objectKey, fileProperties.getSignedUrlExpireSeconds());
        }
        return joinUrl(trimTrailingSlash(config.getDomain()), objectKey);
    }

    @Override
    public String getSignedUrl(String objectKey, long expireSeconds) {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        String publicUrl = joinUrl(trimTrailingSlash(config.getDomain()), objectKey);
        long deadline = System.currentTimeMillis() / 1000L + expireSeconds;
        return auth().privateDownloadUrl(publicUrl, deadline);
    }

    private Auth auth() {
        FileProperties.QiniuOssProperties config = fileProperties.getQiniu();
        return Auth.create(config.getAccessKey(), config.getSecretKey());
    }

    private Configuration configuration() {
        return new Configuration(Region.autoRegion());
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
}
