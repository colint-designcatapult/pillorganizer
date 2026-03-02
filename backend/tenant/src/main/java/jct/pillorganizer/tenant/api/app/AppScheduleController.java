package jct.pillorganizer.tenant.api.app;

import java.util.Optional;

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
import jct.pillorganizer.tenant.dto.SimpleScheduleDTO;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import lombok.extern.flogger.Flogger;

@Controller("/api/v1/device")
@Flogger
public class AppScheduleController {

    @Inject
    AuthService authService;


    @Inject
    DeviceUserRepository deviceUserRepository;

    @Operation(summary = "Get dispense times")
    @Get("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public SimpleScheduleDTO dispenseTimes(@PathVariable("id") String deviceID) {
        throw new RuntimeException("not implemented");
    }

    @Operation(summary = "Update dispense times")
    @Post("/{id}/dispense_time")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public SimpleScheduleDTO updateDispenseTime(@PathVariable("id") String deviceID, @Body SimpleScheduleDTO dto) {
        throw new RuntimeException("not implemented");
    }

}
