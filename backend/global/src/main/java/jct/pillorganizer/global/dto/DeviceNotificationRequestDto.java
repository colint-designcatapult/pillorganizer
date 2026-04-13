package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Request body for {@code POST /user/device/notifications}.
 */
@Serdeable
public record DeviceNotificationRequestDto(
        @NotBlank String deviceId,
        @NotBlank String tenantId,
        @NotNull Boolean subscribe
) {
}
