package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.model.UserEntity;

import java.time.Instant;
import java.util.List;

@Serdeable.Serializable
public record AdminUserDetailDto(
        String userId,
        String userName,
        String email,
        String userSub,
        @Nullable String fcmEndpointArn,
        Instant createdAt,
        Instant lastModified,
        List<AdminDeviceSummaryDto> devices
) {
    public static AdminUserDetailDto from(UserEntity entity, List<AdminDeviceSummaryDto> devices) {
        return new AdminUserDetailDto(
                entity.getUserId(),
                entity.getUserName(),
                entity.getEmail(),
                entity.getUserSub(),
                entity.getFcmEndpointArn(),
                entity.getBase() != null ? entity.getBase().getCreatedAt() : null,
                entity.getBase() != null ? entity.getBase().getLastModified() : null,
                devices
        );
    }
}
