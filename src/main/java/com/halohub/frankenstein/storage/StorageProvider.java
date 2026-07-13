package com.halohub.frankenstein.storage;

import com.halohub.frankenstein.common.enums.OssProviderType;

import java.io.InputStream;

public interface StorageProvider {

    OssProviderType type();

    boolean isConfigured();

    StoredObject upload(StorageUploadRequest request);

    void delete(String objectKey);

    String getAccessUrl(String objectKey);

    String getSignedUrl(String objectKey, long expireSeconds);

    record StorageUploadRequest(
            String originalFilename,
            String contentType,
            long size,
            InputStream inputStream,
            String objectKey
    ) {
    }
}
