package jct.pillorganizer.tenant.auth;

import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.repo.DeviceRepository;

/**
 * Utilities for dealing with devices.
 */
@Singleton
public class DeviceAuthService {

    @Inject
    SecurityService securityService;

    @Inject
    DeviceRepository deviceRepository;

    /**
     * Gets the authentication record of the currently logged-in device, ensuring that a device is logged in.
     * @throws RuntimeException if no device is logged in
     * @return the device's authentication record
     */
    public Authentication getAuthentication() {
        if(!securityService.hasRole("device"))
            throw new RuntimeException("current security context is not a device");
        return securityService.getAuthentication().orElseThrow(() -> new RuntimeException("no authentication"));
    }

    /**
     * Gets the currently logged-in device's serial number
     * @throws RuntimeException if no device authentication exists
     * @return the current device's serial number
     */
    public long getSerialNo() {
        return (long) getAuthentication().getAttributes().get("sn");
    }

    /**
     * Gets the currently logged-in device's ID
     * @throws RuntimeException if no device authentication exists
     * @return the current device's ID
     */
    public long getDeviceID() {
        return (long) getAuthentication().getAttributes().get("id");
    }

    /**
     * Gets the currently logged-in device's Device object
     * @throws RuntimeException if no device authentication exists
     * @return the current device's domain object
     */
    public Device getDevice() {
        return deviceRepository.findById(getDeviceID())
                .orElseThrow(() -> new RuntimeException("device was not found in DB"));
    }


}
