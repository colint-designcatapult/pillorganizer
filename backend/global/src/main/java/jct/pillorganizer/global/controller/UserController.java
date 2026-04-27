package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.global.dto.UserDetailsDto;

import java.util.Optional;

@Controller("/user")
public class UserController {

    @Inject
    SecurityService securityService;

    @Get("/me")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<UserDetailsDto> getUserDetails() {
        return securityService.getAuthentication().map(c ->
                new UserDetailsDto(
                        c.getName(),
                        c.getRoles(),
                        (String) c.getAttributes().get("userId"),
                        (String) c.getAttributes().get("email"),
                        (String) c.getAttributes().get("userDisplayName")
                ));
    }

}
