package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;

/**
 * Internal DTO for inviting a caregiver to a device.
 * Sent from the control plane to the tenant.
 */
@Serdeable
public record InviteCaregiverDto(
        @NotBlank String caregiverUserId,
        @NotBlank String caregiverEmail,
        @Nullable String caregiverUserName,
        @NotBlank String nickname
) {
}
