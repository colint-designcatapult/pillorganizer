package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.global.dto.UserDetailsDto;

import java.util.Collection;
import java.util.Optional;

@Controller("/user")
public class UserController {

    @Inject
    SecurityService securityService;

    @Inject
    TenantService tenantService;

    @Get("/me")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<UserDetailsDto> getUserDetails() {
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

        return securityService.getAuthentication().map(c ->
                new UserDetailsDto(
                        c.getName(),
                        c.getRoles(),
                        (String) c.getAttributes().get("userId"),
                        (String) c.getAttributes().get("email"),
                        (String) c.getAttributes().get("userDisplayName"),
                        adminTenants
                ));
    }

}
