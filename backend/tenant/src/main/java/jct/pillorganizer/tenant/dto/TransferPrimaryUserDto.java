package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record TransferPrimaryUserDto(@NotNull UUID targetCaregiverId) {
}
