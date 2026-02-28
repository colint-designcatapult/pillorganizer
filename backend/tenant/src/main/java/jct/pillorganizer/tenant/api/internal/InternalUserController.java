package jct.pillorganizer.tenant.api.internal;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.service.DeviceUserService;
import reactor.core.publisher.Flux;

import java.util.stream.Collectors;

@Controller("/internal/user")
public class InternalUserController {

    @Inject
    DeviceUserService deviceUserService;

    @Inject
    AuthService authService;

    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Flux<DeviceAccessDto> devices() {
        return deviceUserService.getDeviceAccess(authService.getUser());
    }

}
