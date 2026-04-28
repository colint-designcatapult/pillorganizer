package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.DeviceEntity;

import java.time.Instant;
import java.util.List;

@Serdeable.Serializable
public record AdminDeviceDetailDto(
        String serialNumber,
        String deviceId,
        @Nullable String tenantId,
        @Nullable String thingName,
        @Nullable String claimId,
        Instant createdAt,
        Instant lastModified,
        List<AdminDeviceClaimSummaryDto> claims,
        @Nullable AdminDeviceTenantMappingDto tenantMapping
) {
    public static AdminDeviceDetailDto from(DeviceEntity entity,
                                            List<AdminDeviceClaimSummaryDto> claims,
                                            @Nullable AdminDeviceTenantMappingDto tenantMapping) {
        return new AdminDeviceDetailDto(
                entity.getSerialNumber(),
                entity.getDeviceId(),
                entity.getTenantId(),
                entity.getThingName(),
                entity.getClaimId(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null,
                entity.getBase() != null ? entity.getBase().getLastModified() : null,
                claims,
                tenantMapping
        );
    }
}
