package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

@Introspected
@Serdeable.Serializable
public record UserInfoDTO(long id, String email) {
}
