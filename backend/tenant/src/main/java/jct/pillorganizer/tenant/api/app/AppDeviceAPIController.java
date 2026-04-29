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
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.projection.DoseHistoryView;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository;
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

    @Inject
    DeviceScheduleRepository deviceScheduleRepository;

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
        
        // Fetch device's APPLIED schedule timezone
        var appliedSchedules = deviceScheduleRepository.findByDeviceIdAndStatus(deviceID, ScheduleStatus.APPLIED);
        if (appliedSchedules.isEmpty()) {
            log.atWarning().log("No APPLIED schedules found for device: %s", deviceID);
            return List.of();
        }
        
        String deviceTimeZone = appliedSchedules.get(0).getTimezoneIana();
        if (deviceTimeZone == null) {
            log.atSevere().log("APPLIED schedule has null timezone for device: %s", deviceID);
            return List.of();
        }
        
        List<DoseHistoryView> doseHistory = deviceEventRepository.getResolvedMonthAdherenceHistory(deviceID, year, month, deviceTimeZone);
        
        log.atInfo().log("Query returned %d results for %d-%02d", doseHistory.size(), year, month);
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
