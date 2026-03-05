package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record DeviceEligibilityCheckDto(String deviceId, String serialNo) {
}
