package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.CaregiverListItemDTO;
import jct.pillorganizer.tenant.dto.DeviceCaregiverCodeDTO;
import jct.pillorganizer.tenant.dto.GenerateCaregiverCodeDto;
import jct.pillorganizer.tenant.dto.TransferPrimaryUserDto;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.CaregiverService;
import lombok.extern.flogger.Flogger;

import java.util.List;
import java.util.UUID;

/**
 * API endpoints to interact with caregivers.
 */
@Controller("/api/v1/caregiver")
@Flogger
@Secured(AppSecurityRule.IS_USER)
public class AppCaregiverController {

    @Inject
    CaregiverService caregiverService;

    @Inject
    AuthService authService;

    @Operation(summary = "Validate caregiver's code and join as caregiver")
    @Post("/validate/{code}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> validateCaregiverCode(@PathVariable int code, User user) {
        var result = caregiverService.validateAndJoin(code, user);
        return HttpResponse.ok(result);
    }

    @Operation(summary = "Generate a caregiver invite code for a device")
    @Post("/generate/{deviceId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceCaregiverCodeDTO generateCaregiverCode(@PathVariable String deviceId,
                                                        @Body @Valid GenerateCaregiverCodeDto dto,
                                                        User user) {
        LogicalDevice device = authService.accessDevice(deviceId, true);
        return caregiverService.generateCode(user, device, dto.nickname());
    }

    @Operation(summary = "Get active share codes for devices")
    @Get("/codes")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceCaregiverCodeDTO> getShareCodes(@QueryValue List<String> deviceIds, User user) {
        return caregiverService.getActiveCodesForDevices(deviceIds, user);
    }

    @Operation(summary = "Revoke caregiver's access")
    @Post("/revoke/{caregiverId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> revokeCaregiverAccess(@PathVariable UUID caregiverId, User user) {
        caregiverService.revokeCaregiver(caregiverId, user);
        return HttpResponse.noContent();
    }

    @Operation(summary = "List all users with access to a device")
    @Get("/list/{deviceId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<CaregiverListItemDTO> listCaregivers(@PathVariable String deviceId, User user) {
        return caregiverService.listCaregivers(deviceId, user);
    }

    @Operation(summary = "Transfer primary user status to another caregiver")
    @Post("/transfer/{deviceId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> transferPrimaryUser(@PathVariable String deviceId,
                                               @Body @Valid TransferPrimaryUserDto dto,
                                               User user) {
        caregiverService.transferPrimaryUser(deviceId, dto.targetCaregiverId(), user);
        return HttpResponse.noContent();
    }
}
