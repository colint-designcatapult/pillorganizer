package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Request body sent from the control plane to the tenant module
 * when subscribing or unsubscribing a user from device push notifications.
 */
@Serdeable
public record DeviceSubscribeDto(
        @NotNull Boolean subscribe,
        @NotBlank String endpointArn
) {
}
