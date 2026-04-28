package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;

import java.time.Instant;

@Serdeable.Serializable
public record AdminTenantDeviceRowDto(
        String serialNumber,
        String tenantId,
        @Nullable String deviceId,
        @Nullable String thingName,
        @Nullable String claimId,
        @Nullable Instant mappingCreatedAt,
        @Nullable Instant deviceCreatedAt
) {
    public static AdminTenantDeviceRowDto from(DeviceTenantMappingEntity mapping, @Nullable DeviceEntity device) {
        return new AdminTenantDeviceRowDto(
                mapping.getSerialNumber(),
                mapping.getTenantId(),
                device != null ? device.getDeviceId() : null,
                device != null ? device.getThingName() : null,
                device != null ? device.getClaimId() : null,
                mapping.getBase() != null ? mapping.getBase().getCreatedAt() : null,
                device != null && device.getBase() != null ? device.getBase().getCreatedAt() : null
        );
    }
}
