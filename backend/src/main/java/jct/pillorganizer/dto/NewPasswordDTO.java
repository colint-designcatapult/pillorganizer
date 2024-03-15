package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.Size;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class NewPasswordDTO {
    private static final long MIN_RECOVERY_CODE_VALUE = 100000;
    private static final long MAX_RECOVERY_CODE_VALUE = 999999;
    private static final int MIN_PASSWORD_LENGTH = 6;
    private static final int MAX_PASSWORD_LENGTH = 32;

    @Min(MIN_RECOVERY_CODE_VALUE)
    @Max(MAX_RECOVERY_CODE_VALUE)
    private long recoveryCode;
    private String email;
    @Size(min = MIN_PASSWORD_LENGTH, max = MAX_PASSWORD_LENGTH)
    private String newPassword;
}
