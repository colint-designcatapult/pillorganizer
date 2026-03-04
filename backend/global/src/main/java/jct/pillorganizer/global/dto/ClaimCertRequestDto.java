package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ClaimCertRequestDto(String claimId) {
}
