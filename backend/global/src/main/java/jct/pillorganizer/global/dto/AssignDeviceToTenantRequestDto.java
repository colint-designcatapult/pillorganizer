package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record AssignDeviceToTenantRequestDto(String serialNumber) {}
