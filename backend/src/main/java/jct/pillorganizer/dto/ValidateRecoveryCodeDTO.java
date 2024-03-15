package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;
import javax.validation.Valid;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class ValidateRecoveryCodeDTO {
    private static final long MIN_RECOVERY_CODE_VALUE = 100000;
    private static final long MAX_RECOVERY_CODE_VALUE = 999999;

    private String email;

    @Min(MIN_RECOVERY_CODE_VALUE)
    @Max(MAX_RECOVERY_CODE_VALUE)
    private long recoveryCode;
}
