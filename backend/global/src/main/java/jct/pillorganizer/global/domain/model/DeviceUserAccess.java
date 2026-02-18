package jct.pillorganizer.global.domain.model;

public record DeviceUserAccess(
        String userId,
        String deviceId,
        String tenantId,
        String serialNumber,
        String modelId,
        String userName,
        boolean primaryUser,
        long version
) {
}
