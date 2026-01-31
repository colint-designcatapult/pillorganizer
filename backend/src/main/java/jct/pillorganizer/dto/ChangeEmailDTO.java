package jct.pillorganizer.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class ChangeEmailDTO {
    @Email
    private String currentEmail;
    @Email
    private String newEmail;
}
