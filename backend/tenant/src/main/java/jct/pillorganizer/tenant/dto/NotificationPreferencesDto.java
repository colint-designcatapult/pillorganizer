package jct.pillorganizer.tenant.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

/**
 * Request body for updating per-device notification preferences.
 */
@Serdeable
public record NotificationPreferencesDto(
        @NotNull Boolean notifyTakeNow,
        @NotNull Boolean notifyTaken,
        @NotNull Boolean notifyMissed
) {
}
