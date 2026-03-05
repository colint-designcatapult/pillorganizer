package jct.pillorganizer.tenant.api.internal;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.DeviceIotService;
import jct.pillorganizer.tenant.service.DeviceService;

import java.util.List;
import java.util.Optional;

@Controller("/internal/user")
public class InternalUserController {

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceIotService deviceIotService;


    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceAccessDto> devices(User user) {
        return deviceService.getUserDevices(user);
    }

    @Get("/device_access_policy")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<String> getDevicePolicyDocument(User user, @QueryValue String thingName) {
        Optional<DeviceUser> access = deviceService.getUserAccessByPhysicalDeviceThingName(user, thingName);
        return access.map(du -> deviceIotService.generateDeviceUserAccessPolicyDocument(du));
    }
}
