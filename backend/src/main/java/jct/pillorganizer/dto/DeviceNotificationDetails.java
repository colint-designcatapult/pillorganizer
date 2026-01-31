package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;

import jakarta.annotation.Nullable;
@Introspected
public record DeviceNotificationDetails(@Nullable String deviceName, @Nullable String notificationToken, long deviceID) {
}
