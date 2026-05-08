package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

/**
 * Request body for the device notification subscribe / unsubscribe endpoint.
 * {@code endpointArn} is required when {@code subscribe=true} and ignored when {@code subscribe=false}.
 * Notification preference flags default to {@code true} when not supplied.
 */
@Serdeable
public record DeviceNotificationSubscribeDto(
        @NotNull Boolean subscribe,
        @Nullable String endpointArn,
        @Nullable Boolean notifyTakeNow,
        @Nullable Boolean notifyTaken,
        @Nullable Boolean notifyMissed
) {
    public boolean effectiveNotifyTakeNow() { return notifyTakeNow != null ? notifyTakeNow : true; }
    public boolean effectiveNotifyTaken()   { return notifyTaken != null ? notifyTaken : true; }
    public boolean effectiveNotifyMissed()  { return notifyMissed != null ? notifyMissed : true; }
}
