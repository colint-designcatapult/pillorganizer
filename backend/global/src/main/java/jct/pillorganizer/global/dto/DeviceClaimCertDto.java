package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

import java.time.Instant;

@Serdeable
public record DeviceClaimCertDto(String certificatePem, String privateKey, Instant expiration) {
}
