package com.halohub.frankenstein.storage;

import com.halohub.frankenstein.common.enums.CommonErrorCode;
import com.halohub.frankenstein.common.enums.OssProviderType;
import com.halohub.frankenstein.common.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;

@Component
public class StorageProviderFactory {

    private final Map<OssProviderType, StorageProvider> providerMap;

    public StorageProviderFactory(List<StorageProvider> providers) {
        Map<OssProviderType, StorageProvider> map = new EnumMap<>(OssProviderType.class);
        for (StorageProvider provider : providers) {
            map.put(provider.type(), provider);
        }
        this.providerMap = Map.copyOf(map);
    }

    public StorageProvider get(OssProviderType type) {
        StorageProvider provider = find(type);
        if (provider == null || !provider.isConfigured()) {
            throw new BusinessException(CommonErrorCode.STORAGE_PROVIDER_UNAVAILABLE);
        }
        return provider;
    }

    public StorageProvider find(OssProviderType type) {
        return providerMap.get(type);
    }

    public List<StorageProvider> listConfigured() {
        return providerMap.values().stream()
                .filter(StorageProvider::isConfigured)
                .toList();
    }
}
