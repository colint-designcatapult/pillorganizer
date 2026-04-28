package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import jct.pillorganizer.global.model.DeviceEntity;

import java.time.Instant;

@Serdeable.Serializable
public record AdminDeviceSummaryDto(
        String serialNumber,
        String deviceId,
        String tenantId,
        String thingName,
        Instant createdAt
) {
    public static AdminDeviceSummaryDto from(DeviceEntity entity) {
        return new AdminDeviceSummaryDto(
                entity.getSerialNumber(),
                entity.getDeviceId(),
                entity.getTenantId(),
                entity.getThingName(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null
        );
    }

    public static AdminDeviceSummaryDto fromClaim(DeviceClaimEntity claim) {
        return new AdminDeviceSummaryDto(
                claim.getSerialNumber(),
                claim.getDeviceId(),
                claim.getTenantId(),
                claim.getThingName(),
                claim.getBase() != null ? claim.getBase().getCreatedAt() : null
        );
    }
}
