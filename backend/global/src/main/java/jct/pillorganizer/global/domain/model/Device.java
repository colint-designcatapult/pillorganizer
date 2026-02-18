package jct.pillorganizer.global.domain.model;

public record Device(
        String deviceId,
        String tenantId,
        String serialNumber,
        String modelId,
        ProvisioningStatus provisioningStatus,
        long version
) {
}
