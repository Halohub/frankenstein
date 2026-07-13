package com.halohub.frankenstein.storage;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StoredObject {

    private String objectKey;
    private String url;
    private String contentType;
    private long size;
}
