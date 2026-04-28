package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.UpdateDeviceNickname;
import jct.pillorganizer.tenant.dto.DoseHistoryDto;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import jct.pillorganizer.tenant.service.DeviceService;
import lombok.extern.flogger.Flogger;

import java.time.Instant;
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
    DeviceEventRepository deviceEventRepository;

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

    @Operation(summary = "Retrieves medication adherence history for a device")
    @Get("/{id}/adherencehistory")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DoseHistoryDto> getDeviceAdherenceHistory(@PathVariable("id") String deviceID,
                                                          @QueryValue(defaultValue = "50") int limit) {
        authService.accessDevice(deviceID, false);
        log.atInfo().log("Retrieving adherence history for device: %s, limit: %d", deviceID, limit);
        var doseHistory = deviceEventRepository.getResolvedHistory(deviceID, Instant.now(), limit);
        log.atInfo().log("Query returned %d results", doseHistory.size());
        return doseHistory.stream()
                .map(view -> new DoseHistoryDto(
                        view.logicalDeviceId(),
                        view.epochWeek(),
                        view.binId(),
                        view.scheduledTime(),
                        view.finalStatus(),
                        view.resolvedTime(),
                        view.deviceTimeZone()
                ))
                .toList();
    }

}
