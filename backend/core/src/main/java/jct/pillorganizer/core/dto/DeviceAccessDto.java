package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record DeviceAccessDto(
        String id,
        String nickname,
        String modelId,
        String tenantId,
        String apiBase,
        boolean primaryUser
) {
}
