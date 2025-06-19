package jct.pillorganizer.dto;

import java.util.Date;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.DeviceClass;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record DeviceUserDTO(long id, long deviceID, DeviceClass deviceClass, @Nullable String customName, @Nullable Date lastSync,
                            long serialNo, boolean primaryUser, boolean owner, boolean notifications, @Nullable String timezone) {
}