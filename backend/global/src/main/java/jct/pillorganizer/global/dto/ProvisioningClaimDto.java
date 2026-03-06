package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ProvisioningClaimDto(String claimId, String tenantId, String tenantApiBase, String deviceId,
                                   String claimToken) {
}
