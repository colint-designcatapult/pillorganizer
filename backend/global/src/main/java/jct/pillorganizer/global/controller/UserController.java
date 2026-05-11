package jct.pillorganizer.global.controller;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.global.dto.UserDetailsDto;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.service.UserService;

import java.io.IOException;
import java.util.Collection;
import java.util.Optional;

@Controller("/user")
public class UserController {

    @Inject
    SecurityService securityService;

    @Inject
    TenantService tenantService;

    @Inject
    UserService userService;

    @Get("/me")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<UserDetailsDto> getUserDetails() {
        return securityService.getAuthentication().map(auth -> {
            Collection<TenantDetails> adminTenants;
            if (securityService.hasRole(AppSecurityRule.IS_GLOBAL_ADMIN)) {
                adminTenants = tenantService.getTenantList();
            } else if (securityService.hasRole(AppSecurityRule.IS_ADMIN)) {
                adminTenants = tenantService.getTenantList()
                        .stream()
                        .filter(c -> securityService.hasRole(AppSecurityRule.isTenantAdmin(c.getId())))
                        .toList();
            } else {
                adminTenants = null;
            }

            return new UserDetailsDto(
                    auth.getName(),
                    auth.getRoles(),
                    (String) auth.getAttributes().get("userId"),
                    (String) auth.getAttributes().get("email"),
                    (String) auth.getAttributes().get("userDisplayName"),
                    adminTenants
            );
        });
    }

    @Delete("/me")
    @Secured(AppSecurityRule.IS_USER)
    public HttpResponse<?> deleteAccount() throws IOException {
        String userId = securityService.getAuthentication()
                .map(c -> (String) c.getAttributes().get("userId"))
                .orElseThrow(() -> new HttpStatusException(HttpStatus.UNAUTHORIZED, "Not authenticated"));

        UserEntity user = userService.get(userId)
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND, "User not found"));

        userService.deleteAccount(user);
        return HttpResponse.noContent();
    }

}
