package jct.pillorganizer.tenant.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Request body for the device notification subscribe / unsubscribe endpoint.
 */
@Serdeable
public record DeviceNotificationSubscribeDto(
        @NotNull Boolean subscribe,
        @NotBlank String endpointArn
) {
}
