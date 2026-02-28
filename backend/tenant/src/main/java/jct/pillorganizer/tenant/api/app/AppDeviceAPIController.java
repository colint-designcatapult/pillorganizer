package jct.pillorganizer.tenant.api.app;

import java.text.ParseException;
import java.util.Optional;
import java.util.Set;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.Put;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.auth.DeviceABAC;
import jct.pillorganizer.tenant.auth.DeviceABACIDType;
import jct.pillorganizer.tenant.dto.DeviceStateDTO;
import jct.pillorganizer.tenant.dto.DeviceUserDTO;
import jct.pillorganizer.tenant.dto.UpdateDeviceUserSettings;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.repo.DeviceRepository;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import jct.pillorganizer.tenant.service.DeviceUserService;
import lombok.extern.flogger.Flogger;

/**
 * API endpoints for the app to configure and view device information and state.
 */
@Controller("/api/v1/device")
@Flogger
public class AppDeviceAPIController {

    @Inject
    DeviceRepository deviceRepository;


    @Inject
    AuthService authService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceUserService deviceUserService;

    @Operation(summary = "Lists devices that the user has access to")
    @Get("/list")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Set<DeviceUserDTO> listDeviceUser() {
        return deviceUserService.getDevices(authService.getUser());
    }

    @Operation(summary = "Checks if the user has access to a device with the given claim token")
    @Post("/check")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<DeviceUserDTO> checkDeviceAccess(@QueryValue("claimToken") String claimToken) {
        return deviceUserService.getDeviceByClaimToken(authService.getUser(), claimToken);
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
    public Device device(@PathVariable String id) {
        return deviceRepository.findById(id).get();
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
