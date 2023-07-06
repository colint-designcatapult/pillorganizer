package jct.pillorganizer.controller.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.SimpleScheduleDTO;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.service.DeviceScheduleService;
import lombok.extern.flogger.Flogger;

@Controller("/api/v1/device")
@Flogger
public class AppScheduleController {

    @Inject
    AuthService authService;

    @Inject
    DeviceScheduleService deviceScheduleService;

    @Operation(summary = "Get dispense times")
    @Get("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public SimpleScheduleDTO dispenseTimes(@PathVariable("id") long deviceID) {
        Device d = authService.accessDevice(deviceID);
        return deviceScheduleService.buildSimpleSchedule(d);
    }

    @Operation(summary = "Update dispense times")
    @Post("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public SimpleScheduleDTO updateDispenseTime(@PathVariable("id") long deviceID, @Body SimpleScheduleDTO dto) {
        Device d = authService.accessDevice(deviceID);
        return deviceScheduleService.updateSchedule(d, dto);
    }

}
