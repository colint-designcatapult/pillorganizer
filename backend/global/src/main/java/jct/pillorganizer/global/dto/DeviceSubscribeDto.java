package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

/**
 * Request body sent from the control plane to the tenant module
 * when subscribing or unsubscribing a user from device push notifications.
 * {@code endpointArn} is required when {@code subscribe=true} and ignored when {@code subscribe=false}.
 */
@Serdeable
public record DeviceSubscribeDto(
        @NotNull Boolean subscribe,
        @Nullable String endpointArn,
        @Nullable Boolean notifyTakeNow,
        @Nullable Boolean notifyTaken,
        @Nullable Boolean notifyMissed
) {
}
