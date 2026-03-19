package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.DeviceScheduleStateDTO;
import jct.pillorganizer.tenant.model.schedule.SimpleSchedule;
import jct.pillorganizer.tenant.service.ScheduleService;
import lombok.extern.flogger.Flogger;

@Controller("/api/v1/device")
@Flogger
public class AppScheduleController {

    @Inject
    AuthService authService;

    @Inject
    ScheduleService scheduleService;

    @Operation(summary = "Get the current and pending schedule for a device")
    @Get("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceScheduleStateDTO dispenseTimes(@PathVariable("id") String deviceID) {
        authService.accessDevice(deviceID);
        return scheduleService.getSchedule(deviceID);
    }

    @Operation(summary = "Request a new schedule for a device")
    @Post("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceScheduleStateDTO updateDispenseTime(@PathVariable("id") String deviceID,
                                                      @Body SimpleSchedule dto) {
        authService.accessDevice(deviceID);
        return scheduleService.setSchedule(deviceID, dto, authService.getUser());
    }
}
