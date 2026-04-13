package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

/**
 * Request body for the device notification subscribe / unsubscribe endpoint.
 * {@code endpointArn} is required when {@code subscribe=true} and ignored when {@code subscribe=false}.
 */
@Serdeable
public record DeviceNotificationSubscribeDto(
        @NotNull Boolean subscribe,
        @Nullable String endpointArn
) {
}
