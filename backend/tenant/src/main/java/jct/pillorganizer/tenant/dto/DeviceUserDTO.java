package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.DeviceClass;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record DeviceUserDTO(String id, DeviceClass deviceClass, @Nullable String customName,
                            String serialNo, boolean primaryUser) {
}