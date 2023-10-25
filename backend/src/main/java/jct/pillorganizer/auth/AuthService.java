package jct.pillorganizer.auth;

import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.user.User;
import jct.pillorganizer.model.user.UserRole;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceUserAsyncRepository;
import jct.pillorganizer.repo.DeviceUserRepository;
import org.mindrot.jbcrypt.BCrypt;
import reactor.core.publisher.Mono;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/**
 * Utility functions for dealing with authentication and authorization.
 * Plaintext passwords are stored as a character array for security, since it helps prevent accidental leakage through
 * logging.
 */
@Singleton
public class AuthService {
    @Inject
    SecurityService securityService;

    @Inject
    DeviceUserAsyncRepository asyncRepository;
    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceRepository deviceRepository;


    // todo: why ascii here? check if there are any weird side effects
    private static final Charset HASH_CARSET = StandardCharsets.US_ASCII;

    /**
     * Check if the specified password matches the user's password.
     * @param user the user to check the password for
     * @param password a character array of the password to check
     * @return true if the password matches, false otherwise
     */
    public boolean checkPassword(User user, char[] password) {
        return checkPassword(user.getPasswordHash(), password);
    }

    private boolean checkPassword(byte[] hash, char[] password) {
        return BCrypt.checkpw(String.valueOf(password), new String(hash, HASH_CARSET));
    }

    /**
     * Hashes a plaintext password into a secure hash format.
     * @param plaintext the plaintext password to hash, as a character array.
     * @return the hashed password as a byte array
     */
    public byte[] hashPassword(char[] plaintext) {
        return BCrypt.hashpw(String.valueOf(plaintext), BCrypt.gensalt(10)).getBytes(HASH_CARSET);
    }

    /**
     * Converts a plaintext password in string form to a character array.
     * @param plaintextPassword a plaintext password in string form
     * @return the plaintext password as a character array
     */
    public char[] toCharArray(String plaintextPassword) {
        return plaintextPassword.toCharArray();
    }

    /**
     * Gets the currently logged-in user ID. Note that if the user type is Device, this will return a device ID and not
     * a user ID.
     * @throws AuthenticationException if no user is currently signed in
     * @return a user ID or device ID of the currently logged-in user
     */
    public long getUserID() {
        return (long)securityService.getAuthentication()
                .orElseThrow(() -> new AuthenticationException("No authentication")).getAttributes().get("id");
    }

    /**
     * Attempt to asynchronously access a device using the currently logged-in user's credentials.
     * @param deviceID device ID to access
     * @return a Mono wrapping a future device
     */
    public Mono<Device> accessDeviceAsync(long deviceID) {
        return asyncRepository.retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(getUserID(), deviceID);
    }

    /**
     * Attempt to access a device using the currently logged-in user's credentials.
     * @param deviceID device ID to access
     * @return the Device object if the user has access to the specified device
     * @throws RuntimeException if no device with the specified ID exists
     * @throws AuthenticationException if the user doesn't have access to the specified device
     */
    public Device accessDevice(long deviceID) {
        if(isAdmin()) {
            return deviceRepository.findById(deviceID)
                    .orElseThrow(() -> new RuntimeException("Device ID does not exist"));
        } else {
            return deviceUserRepository.retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(getUserID(), deviceID)
                    .orElseThrow(() -> new AuthenticationException("No access"));
        }
    }

    /**
     * Check if the currently logged-in user has the administrator role.
     * @return true if the logged-in user is an administrator, false otherwise
     */
    public boolean isAdmin() {
        return securityService.hasRole(UserRole.ADMIN.toString());
    }

}
