package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

/**
 * DTO sent from the control plane to the tenant when inviting a caregiver.
 */
@Serdeable
public record InviteCaregiverTenantDto(
        String caregiverUserId,
        String caregiverEmail,
        @Nullable String caregiverUserName,
        String nickname
) {
}
