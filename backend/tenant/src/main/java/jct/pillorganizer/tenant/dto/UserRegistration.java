package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class UserRegistration {
    @Email
    private String email;
    @Size(min = 6, max = 32)
    private String password;
}
