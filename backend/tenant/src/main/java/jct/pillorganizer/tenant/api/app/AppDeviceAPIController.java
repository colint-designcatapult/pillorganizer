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
import jct.pillorganizer.tenant.dto.MonthDaysWithDataDto;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.projection.DoseHistoryView;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository;
import jct.pillorganizer.tenant.service.DeviceService;
import lombok.extern.flogger.Flogger;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

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

    @Operation(summary = "Retrieves medication adherence history for a device")
    @Get("/{id}/adherencehistory")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DoseHistoryDto> getDeviceAdherenceHistory(@PathVariable("id") String deviceID,
                                                          @QueryValue(defaultValue = "50") int limit,
                                                          @QueryValue Optional<LocalDate> date) {
        authService.accessDevice(deviceID, false);
        log.atInfo().log("Retrieving adherence history for device: %s, limit: %d", deviceID, limit);
        
        List<DoseHistoryView> doseHistory;
        if (date.isPresent()) {
            // Query for specific date in device's timezone
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
            ZoneId zoneId = ZoneId.of(deviceTimeZone);
            
            LocalDateTime startOfDay = date.get().atStartOfDay();
            LocalDateTime endOfDay = date.get().plusDays(1).atStartOfDay();
            
            Instant startUtc = startOfDay.atZone(zoneId).toInstant();
            Instant endUtc = endOfDay.atZone(zoneId).toInstant();
            
            log.atInfo().log("Querying adherence history for date: %s in timezone: %s (UTC: %s to %s)", 
                date.get(), deviceTimeZone, startUtc, endUtc);
            
            doseHistory = deviceEventRepository.getResolvedHistoryByDateRange(deviceID, startUtc, endUtc, limit);
        } else {
            // Default: query last 14 days from now
            doseHistory = deviceEventRepository.getResolvedHistory(deviceID, Instant.now(), limit);
        }
        
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

    @Operation(summary = "Retrieves days with adherence data for a given month")
    @Get("/{id}/adherencehistory/month-days-with-data")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public MonthDaysWithDataDto getMonthDaysWithData(@PathVariable("id") String deviceID,
                                                      @QueryValue int year,
                                                      @QueryValue int month) {
        authService.accessDevice(deviceID, false);
        log.atInfo().log("Retrieving days with data for device: %s, year: %d, month: %d", deviceID, year, month);
        
        // Fetch device's APPLIED schedule timezone
        var appliedSchedules = deviceScheduleRepository.findByDeviceIdAndStatus(deviceID, ScheduleStatus.APPLIED);
        if (appliedSchedules.isEmpty()) {
            log.atWarning().log("No APPLIED schedules found for device: %s", deviceID);
            return new MonthDaysWithDataDto(year, month, List.of());
        }
        
        String deviceTimeZone = appliedSchedules.get(0).getTimezoneIana();
        if (deviceTimeZone == null) {
            log.atSevere().log("APPLIED schedule has null timezone for device: %s", deviceID);
            return new MonthDaysWithDataDto(year, month, List.of());
        }
        var daysWithData = deviceEventRepository.getMonthDaysWithData(deviceID, year, month, deviceTimeZone);
        
        // Handle null result from empty query
        if (daysWithData == null) {
            daysWithData = List.of();
        }
        
        log.atInfo().log("Found %d days with data for %d-%02d", daysWithData.size(), year, month);
        return new MonthDaysWithDataDto(year, month, daysWithData);
    }

}
