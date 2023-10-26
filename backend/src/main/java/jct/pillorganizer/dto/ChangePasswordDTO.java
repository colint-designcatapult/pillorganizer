package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.Size;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class ChangePasswordDTO {
    @Size(min = 6, max = 32)
    private String currentPassword;
    @Size(min = 6, max = 32)
    private String newPassword;
}
