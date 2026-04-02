package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Size;

import java.util.Optional;

@Introspected
@Serdeable.Deserializable
@Serdeable.Serializable
public record UpdateDeviceNickname(
        @Size(min = 3, max = 32)
        String deviceName
) {
}
