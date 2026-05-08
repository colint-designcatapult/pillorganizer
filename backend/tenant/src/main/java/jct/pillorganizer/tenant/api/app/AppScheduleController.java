package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import jakarta.validation.Valid;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.DeviceScheduleStateDTO;
import jct.pillorganizer.tenant.dto.SetScheduleRequestDTO;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.ScheduleService;
import lombok.extern.flogger.Flogger;

import java.util.Base64;

@Controller("/api/v1/device")
@Flogger
@Secured(AppSecurityRule.IS_USER)
public class AppScheduleController {

    @Inject
    AuthService authService;

    @Inject
    ScheduleService scheduleService;

    @Inject
    TenantService tenantService;

    @Operation(summary = "Get the current and pending schedule for a device")
    @Get("/{id}/schedule")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceScheduleStateDTO dispenseTimes(@PathVariable("id") String deviceID) {
        return scheduleService.getSchedule(authService.accessDevice(deviceID, false));
    }

    @Operation(summary = "Request a new schedule for a device")
    @Post("/{id}/schedule")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceScheduleStateDTO updateDispenseTime(@PathVariable("id") String deviceID,
                                                     @Body @Valid SetScheduleRequestDTO dto, User user) {
        return scheduleService.setSchedule(
                authService.accessDevice(deviceID, true),
                dto.schedule(),
                dto.takeEffect(),
                dto.timezoneIana(),
                user
        );
    }

    @Operation(summary = "Get the tenant's default schedule, if configured")
    @Get("/default-schedule")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<BaseSchedule> getDefaultSchedule() {
        return tenantService.getCurrentTenant()
                .map(TenantDetails::getDefaultSchedule)
                .filter(encoded -> encoded != null && !encoded.isBlank())
                .map(encoded -> {
                    String json = new String(Base64.getDecoder().decode(encoded));
                    BaseSchedule schedule = scheduleService.parseScheduleJson(json);
                    if (schedule == null) {
                        return HttpResponse.<BaseSchedule>notFound();
                    }
                    return HttpResponse.ok(schedule);
                })
                .orElse(HttpResponse.notFound());
    }
}
