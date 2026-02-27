package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ProvisioningClaimDto(String certificatePem, String privateKey,
                                   String expiration, String claimId, String tenantId) {
}
