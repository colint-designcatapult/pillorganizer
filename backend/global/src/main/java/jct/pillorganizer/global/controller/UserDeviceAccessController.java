package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.global.dto.UserAndDeviceAccessDto;
import jct.pillorganizer.global.service.UserDeviceAccessService;
import reactor.core.publisher.Mono;

@Controller("/user")
public class UserDeviceAccessController {

    @Inject
    UserDeviceAccessService userDeviceAccessService;

    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<UserAndDeviceAccessDto> test() {
        return userDeviceAccessService.getUserDeviceAccess()
                .collectList()
                .map(UserAndDeviceAccessDto::new);
    }

}
