package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.DeviceClaimEntity;

import java.time.Instant;

@Serdeable.Serializable
public record AdminDeviceClaimSummaryDto(
        String serialNumber,
        String claimId,
        @Nullable String userId,
        @Nullable String deviceId,
        @Nullable String thingName,
        @Nullable String tenantId,
        @Nullable Instant createdAt
) {
    public static AdminDeviceClaimSummaryDto from(DeviceClaimEntity entity) {
        return new AdminDeviceClaimSummaryDto(
                entity.getSerialNumber(),
                entity.getClaimId(),
                entity.getUserId(),
                entity.getDeviceId(),
                entity.getThingName(),
                entity.getTenantId(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null
        );
    }
}
