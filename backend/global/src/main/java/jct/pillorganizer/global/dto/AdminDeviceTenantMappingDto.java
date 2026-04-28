package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;

import java.time.Instant;

@Serdeable.Serializable
public record AdminDeviceTenantMappingDto(
        String serialNumber,
        String tenantId,
        @Nullable Instant createdAt,
        @Nullable Instant lastModified
) {
    public static AdminDeviceTenantMappingDto from(DeviceTenantMappingEntity entity) {
        return new AdminDeviceTenantMappingDto(
                entity.getSerialNumber(),
                entity.getTenantId(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null,
                entity.getBase() != null ? entity.getBase().getLastModified() : null
        );
    }
}
