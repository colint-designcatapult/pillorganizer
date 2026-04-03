package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.UpdateDeviceNickname;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.service.DeviceProvisionService;
import jct.pillorganizer.tenant.service.DeviceService;
import lombok.extern.flogger.Flogger;

/**
 * API endpoints for the app to configure and view device information and state.
 */
@Controller("/api/v1/device")
@Flogger
public class AppDeviceAPIController {

    @Inject
    DeviceService deviceService;

    @Inject
    AuthService authService;

    @Inject
    private DeviceProvisionService deviceProvisionService;

    @Operation(summary = "Updates the device nickname")
    @Post("/{id}/nickname")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public LogicalDevice setDeviceNickname(@PathVariable("id") String deviceID,
                                           @Body @Valid UpdateDeviceNickname dto) {
        LogicalDevice device = authService.accessDevice(deviceID, true);
        return deviceService.updateNickname(device, dto.deviceName());
    }

}
