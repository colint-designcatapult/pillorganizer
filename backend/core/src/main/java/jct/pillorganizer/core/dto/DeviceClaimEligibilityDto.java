package jct.pillorganizer.core.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record DeviceClaimEligibilityDto(boolean isEligible, boolean deviceExists) {
}
