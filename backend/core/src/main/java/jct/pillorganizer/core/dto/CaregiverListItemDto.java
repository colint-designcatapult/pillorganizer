package jct.pillorganizer.core.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.UUID;

@Serdeable
public record CaregiverListItemDto(UUID id, String userName, @Nullable String nickname, boolean primaryUser) {
}
