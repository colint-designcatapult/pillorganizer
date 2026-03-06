package jct.pillorganizer.tenant.api.app;

import java.text.ParseException;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.auth.DeviceABAC;
import jct.pillorganizer.tenant.auth.DeviceABACIDType;
import jct.pillorganizer.tenant.dto.AssignDeviceDTO;
import jct.pillorganizer.tenant.dto.DeviceStateDTO;
import jct.pillorganizer.tenant.dto.DeviceUserDTO;
import jct.pillorganizer.tenant.dto.UpdateDeviceUserSettings;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.exceptions.DeviceProvisionNotFoundException;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
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

    @Operation(summary = "Lists devices that the user has access to")
    @Get("/list")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceAccessDto> listDeviceUser(User user) {
        return deviceService.getUserDevices(user);
    }

    @Operation(summary = "Soft deletes the device user link")
    @Delete("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> removeDeviceFromUser(@PathVariable String id) {
        throw new RuntimeException("not implemented");
    }


    @Operation(summary = "Queries info about a device")
    @Get("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public LogicalDevice device(@PathVariable UUID id) {
        throw new RuntimeException("not implemented");
        //return deviceRepository.findById(id).get();
    }

    @Operation(summary = "Reloads the pills on a device")
    @Post("/{id}/reload")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public void reload(@PathVariable String id) {
        throw new IllegalStateException("not implemented");
    }

    @Operation(summary = "Updates device basic settings", description = "Updates non-schedule settings for a device, including timezone, name, and notification token.")
    @Put("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @DeviceABAC
    public DeviceUserDTO setDeviceSettings(
            @DeviceABAC(idType = DeviceABACIDType.DEVICE) @PathVariable("id") String deviceID,
            @Body UpdateDeviceUserSettings dto) {
        throw new RuntimeException("not implemented");
    }

    @Operation(summary = "Get device state on a particular date")
    @Post(value = "/{id}/state", consumes = { MediaType.APPLICATION_FORM_URLENCODED })
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @DeviceABAC
    public DeviceStateDTO consolidatedState(@DeviceABAC(idType = DeviceABACIDType.DEVICE) @PathVariable String id,
            @QueryValue("date") String dateString) throws ParseException {

        throw new RuntimeException("Not implemented yet");
    }

}
