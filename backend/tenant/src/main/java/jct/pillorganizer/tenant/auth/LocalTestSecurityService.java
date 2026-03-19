package jct.pillorganizer.tenant.auth;

import io.micronaut.context.annotation.Requires;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Singleton;

import java.util.Optional;

/**
 * No-op SecurityService stub active only in the "localtest" environment.
 * Satisfies injection points for classes that depend on SecurityService
 * when the security module is fully disabled (micronaut.security.enabled=false).
 */
@Singleton
@Requires(env = "localtest")
public class LocalTestSecurityService implements SecurityService {

    @Override
    public Optional<String> username() {
        return Optional.empty();
    }

    @Override
    public Optional<Authentication> getAuthentication() {
        return Optional.empty();
    }

    @Override
    public boolean isAuthenticated() {
        return false;
    }

    @Override
    public boolean hasRole(String role) {
        return false;
    }
}
