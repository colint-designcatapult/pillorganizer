package jct.pillorganizer.tenant.auth;

import com.google.common.flogger.FluentLogger;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.user.UserRole;
import jct.pillorganizer.tenant.repo.DeviceRepository;
import jct.pillorganizer.tenant.repo.DeviceUserAsyncRepository;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;

import reactor.core.publisher.Mono;

import java.util.Optional;

/**
 * Utility functions for dealing with authentication and authorization.
 * Plaintext passwords are stored as a character array for security, since it
 * helps prevent accidental leakage through logging.
 */
@Singleton
public class AuthService {
    private static final FluentLogger log = FluentLogger.forEnclosingClass();
    @Inject
    SecurityService securityService;

    @Inject
    DeviceUserAsyncRepository asyncRepository;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceRepository deviceRepository;

    /**
     * Gets the currently logged-in user ID. Note that if the user type is Device,
     * this will return a device ID and not
     * a user ID.
     * 
     * @throws AuthenticationException if no user is currently signed in
     * @return a user ID or device ID of the currently logged-in user
     */
    public long getUserID() {
        Optional<Authentication> auth = securityService.getAuthentication();
        return (long) auth.orElseThrow(() -> new AuthenticationException("No authentication"))
                .getAttributes()
                .get("id");
    }

    /**
     * Attempt to asynchronously access a device using the currently logged-in
     * user's credentials.
     * 
     * @param deviceID device ID to access
     * @return a Mono wrapping a future device
     */
    public Mono<Device> accessDeviceAsync(long deviceID) {
        return asyncRepository.retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(getUserID(), deviceID);
    }

    /**
     * Attempt to access a device using the currently logged-in user's credentials.
     * 
     * @param deviceID device ID to access
     * @return the Device object if the user has access to the specified device
     * @throws RuntimeException        if no device with the specified ID exists
     * @throws AuthenticationException if the user doesn't have access to the
     *                                 specified device
     */
    public Device accessDevice(long deviceID) {
        if (isAdmin()) {
            return deviceRepository.findById(deviceID)
                    .orElseThrow(() -> new RuntimeException("Device ID does not exist"));
        } else {
            return deviceUserRepository.retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(getUserID(), deviceID)
                    .orElseThrow(() -> new AuthenticationException("No access"));
        }
    }

    /**
     * Check if the currently logged-in user has the administrator role.
     * 
     * @return true if the logged-in user is an administrator, false otherwise
     */
    public boolean isAdmin() {
        return securityService.hasRole(UserRole.ADMIN.toString());
    }

}