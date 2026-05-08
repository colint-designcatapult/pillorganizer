package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * Request body for {@code POST /user/device/invite-caregiver}.
 * The primary user invites a caregiver by email.
 */
@Serdeable
public record InviteCaregiverRequestDto(
        @NotBlank @Email String email,
        @NotBlank String nickname,
        @NotBlank String deviceId,
        @NotBlank String tenantId
) {
}
