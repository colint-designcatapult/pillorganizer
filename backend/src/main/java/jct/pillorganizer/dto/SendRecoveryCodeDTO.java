package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;
import jakarta.validation.Valid;

@Introspected
@Data
@Serdeable.Deserializable
@Valid
public class SendRecoveryCodeDTO {
    private String sendTo;
}
