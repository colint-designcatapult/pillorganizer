package jct.pillorganizer.tenant.api.internal;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.DeviceService;

import java.util.List;

@Controller("/internal/user")
public class InternalUserController {

    @Inject
    DeviceService deviceService;


    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceAccessDto> devices(User user) {
        return deviceService.getUserDevices(user);
    }

}
