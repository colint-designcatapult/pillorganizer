package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;

/**
 * Request body for {@code POST /user/fcm_token}.
 */
@Serdeable
public record RegisterFcmTokenDto(
        @NotBlank String fcmToken
) {
}
