package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record DeviceAccessDto(
        String deviceId,
        String claimId,
        String nickname,
        String serialNo,
        String modelId,
        String tenantId,
        String apiBase,
        boolean primaryUser,
        String thingName
) {
}
