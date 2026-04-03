package jct.pillorganizer.tenant.auth;

import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;

import jct.pillorganizer.tenant.service.RequestCacheService;
import lombok.extern.flogger.Flogger;

/**
 * Utility functions for dealing with authentication and authorization.
 */
@Singleton
@Flogger
public class AuthService {

    public LogicalDevice accessDevice(String deviceId, boolean primaryUser) {
        return RequestCacheService.getDevice(deviceId)
                .filter(u -> !primaryUser || u.isPrimaryUser())
                .map(DeviceUser::getDevice)
                .orElseThrow(() -> new DeviceAccessException("No access to device"));
    }

}
