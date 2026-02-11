package jct.pillorganizer.tenant.auth;

import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

/**
 * Utilities for dealing with anonymous users.
 */
@Singleton
public class AnonAuthService {
    @Inject
    SecurityService securityService;


    /**
     * Gets the authentication record, ensuring that an anonymous user is currently signed in.
     * @throws RuntimeException if no such anonymous user exists
     * @return the authentication record of the current anonymous user
     */
    public Authentication getAuthentication() {
        if(!securityService.hasRole("anon"))
            throw new RuntimeException("current security context is not an anonymous user");
        return securityService.getAuthentication().orElseThrow(() -> new RuntimeException("No authentication"));
    }

    /**
     * Gets the current anonymous user's ID, ensuring that an anonymous user is currently signed in.
     * @throws RuntimeException if no such anonymous user exists
     * @return the ID of the current anonymous user
     */
    public long getUserID() {
        return (long)getAuthentication().getAttributes().get("id");
    }

}
