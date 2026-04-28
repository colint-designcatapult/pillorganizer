package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.UserEntity;

import java.time.Instant;

@Serdeable.Serializable
public record AdminUserSummaryDto(
        String userId,
        String userName,
        String email,
        Instant createdAt
) {
    public static AdminUserSummaryDto from(UserEntity entity) {
        return new AdminUserSummaryDto(
                entity.getUserId(),
                entity.getUserName(),
                entity.getEmail(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null
        );
    }
}
