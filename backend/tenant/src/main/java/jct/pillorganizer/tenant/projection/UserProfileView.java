package jct.pillorganizer.tenant.projection;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.dto.DeviceAccessDto;

import java.util.List;

@Serdeable
public record UserProfileView(
        String id,
        String userType,
        String name,
        String email,
        List<DeviceAccessDto> devices
) {
}
