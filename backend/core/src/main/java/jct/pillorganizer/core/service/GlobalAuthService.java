package jct.pillorganizer.core.service;

import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.Optional;

@Singleton
public class GlobalAuthService {

    @Inject
    SecurityService securityService;

    public String getUserID() {
        Optional<Authentication> auth = securityService.getAuthentication();
        return auth.orElseThrow(() -> new AuthenticationException("No authentication"))
                .getAttributes()
                .get("userId").toString();
    }

}
