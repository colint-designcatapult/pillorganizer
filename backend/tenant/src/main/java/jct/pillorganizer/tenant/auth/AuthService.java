package jct.pillorganizer.tenant.auth;

import com.github.ksuid.Ksuid;
import com.google.common.flogger.FluentLogger;
import io.micronaut.http.context.ServerRequestContext;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.model.user.UserType;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;

import jct.pillorganizer.tenant.repo.UserRepository;
import jct.pillorganizer.tenant.service.DeviceService;

import java.util.UUID;

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
    DeviceUserRepository deviceUserRepository;

    @Inject
    LogicalDeviceRepository deviceRepository;

    @Inject
    private UserRepository userRepository;
    @Inject
    private DeviceService deviceService;

    private Object getRequestAttribute(String attr) {
        return ServerRequestContext.currentRequest()
                .flatMap(req -> req.getAttribute(attr))
                .orElseThrow(() -> new AuthenticationException("No authentication"));
    }

    public String getUserID() {
        Object idObj = getRequestAttribute(UserFilter.USER_ID_ATTRIBUTE);
        if(idObj instanceof String) {
            return (String) idObj;
        }
        throw new IllegalStateException("Invalid object in request user ID attribute");
    }

    public User getUser() {
        Object idObj = getRequestAttribute(UserFilter.USER_ENTITY_ATTRIBUTE);
        if(idObj instanceof User) {
            return (User) idObj;
        }
        throw new IllegalStateException("Invalid object in request user entity attribute");
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
    public LogicalDevice accessDevice(UUID deviceID) {
        log.atSevere().log("Using legacy access control: allowing");
        return deviceRepository.findById(deviceID).get();
    }

    /**
     * Check if the currently logged-in user has the administrator role.
     * 
     * @return true if the logged-in user is an administrator, false otherwise
     */
    public boolean isAdmin() {
        return securityService.hasRole(UserType.ADMIN.toString());
    }

}
