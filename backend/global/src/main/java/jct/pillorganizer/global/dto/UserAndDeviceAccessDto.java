package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.dto.DeviceAccessDto;

import java.util.List;

@Serdeable.Serializable
public record UserAndDeviceAccessDto(
        List<DeviceAccessDto> devices
) {
}
