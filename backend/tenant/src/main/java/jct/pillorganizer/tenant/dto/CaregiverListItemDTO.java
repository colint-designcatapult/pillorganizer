package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.UUID;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record CaregiverListItemDTO(UUID id, String userName, @Nullable String nickname, boolean primaryUser) {
}
