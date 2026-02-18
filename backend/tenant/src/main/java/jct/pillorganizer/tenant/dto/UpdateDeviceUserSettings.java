package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

import java.util.Optional;

@Introspected
@Serdeable.Deserializable
@Serdeable.Serializable
public record UpdateDeviceUserSettings(Optional<String> deviceName, Optional<String> notificationToken,
                                       Optional<Boolean> notifications, Optional<String> timezone) {
}
