package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.DeviceCommandDto;
import jct.pillorganizer.tenant.dto.UpdateDeviceNickname;
import jct.pillorganizer.tenant.dto.DoseHistoryDto;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.AdherenceService;
import jct.pillorganizer.tenant.service.DeviceCommandService;
import jct.pillorganizer.tenant.service.DeviceService;
import lombok.extern.flogger.Flogger;

import java.io.IOException;
import java.util.List;

/**
 * API endpoints for the app to configure and view device information and state.
 */
@Controller("/api/v1/device")
@Flogger
@Secured(AppSecurityRule.IS_USER)
public class AppDeviceAPIController {

    @Inject
    DeviceService deviceService;

    @Inject
    AuthService authService;

    @Inject
    AdherenceService adherenceService;

    @Inject
    DeviceCommandService deviceCommandService;

    @Operation(summary = "Lists devices that the user has access to")
    @Get("/list")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceAccessDto> listDeviceUser(User user) {
        return deviceService.getUserDevices(user);
    }

    @Operation(summary = "Updates the device nickname")
    @Post("/{id}/nickname")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceAccessDto setDeviceNickname(@PathVariable("id") String deviceID,
                                             @Body @Valid UpdateDeviceNickname dto, User user) {
        var device = authService.accessDevice(deviceID, true);
        deviceService.updateNickname(device, dto.deviceName());
        return deviceService.getUserDevice(user, device)
                .orElseThrow(() -> new io.micronaut.http.exceptions.HttpStatusException(
                        io.micronaut.http.HttpStatus.NOT_FOUND, "Device not found"));
    }

    @Operation(summary = "Retrieves medication adherence history for an entire month")
    @Get("/{id}/adherencehistory")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DoseHistoryDto> getDeviceAdherenceHistory(@PathVariable("id") String deviceID,
                                                          @QueryValue int year,
                                                          @QueryValue int month) {
        authService.accessDevice(deviceID, false);
        log.atInfo().log("Retrieving adherence history for device: %s, year: %d, month: %d", deviceID, year, month);
        return adherenceService.getAdherenceHistory(deviceID, year, month);
    }

    @Operation(summary = "Sends a command to the device firmware via MQTT")
    @Post("/{id}/command")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> sendCommand(@PathVariable("id") String deviceID,
                                       @Body @Valid DeviceCommandDto dto) throws IOException {
        // Validate required fields per command type
        switch (dto.type()) {
            case RELOAD -> {
                if (dto.reload() == null) {
                    throw new io.micronaut.http.exceptions.HttpStatusException(
                            io.micronaut.http.HttpStatus.BAD_REQUEST, "RELOAD command requires 'reload' field");
                }
            }
            case BIN -> {
                if (dto.binId() == null || dto.binAction() == null) {
                    throw new io.micronaut.http.exceptions.HttpStatusException(
                            io.micronaut.http.HttpStatus.BAD_REQUEST, "BIN command requires 'binId' and 'binAction' fields");
                }
            }
        }

        var device = authService.accessDevice(deviceID, true);
        if (device.getPhysicalDevice() == null || device.getPhysicalDevice().getThingName() == null) {
            throw new io.micronaut.http.exceptions.HttpStatusException(
                    io.micronaut.http.HttpStatus.BAD_REQUEST, "Device has no associated thing name");
        }
        deviceCommandService.sendCommand(device.getPhysicalDevice().getThingName(), dto);
        return HttpResponse.accepted();
    }

}
