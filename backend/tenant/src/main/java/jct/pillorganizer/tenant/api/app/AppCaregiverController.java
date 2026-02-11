package jct.pillorganizer.tenant.api.app;

import java.util.List;
import java.util.Map;

import org.zalando.problem.Problem;
import org.zalando.problem.Status;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.DeviceCaregiverCodeDTO;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.device.DeviceCaregiverCode;
import jct.pillorganizer.tenant.service.CaregiverService;
import jct.pillorganizer.tenant.service.DeviceService;
import jct.pillorganizer.tenant.service.DeviceUserService;
import lombok.extern.flogger.Flogger;

/**
 * API endpoints to interact with caregivers.
 */
@Controller("/api/v1/caregiver")
@Flogger
public class AppCaregiverController {
    @Inject
    AuthService authService;

    @Inject
    CaregiverService caregiverService;

    @Inject
    DeviceUserService deviceUserService;

    @Inject
    private DeviceService deviceService;



    @Operation(summary = "Validate caregiver's code")
    @Post("/validate/{code}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> validateCaregiverCode(@PathVariable long code) {
        long userID = authService.getUserID();
        DeviceCaregiverCode caregiverCode = caregiverService.findCaregiverCode(code);

        if (caregiverCode == null) {
            return HttpResponse.status(HttpStatus.BAD_REQUEST)
                    .body(Problem.builder()
                            .withStatus(Status.BAD_REQUEST)
                            .withTitle("INVALID_CAREGIVER_CODE")
                            .withDetail("The provided caregiver code is invalid or has expired: " + code)
                            .build());
        }

        deviceUserService.addUserToDevice(userID, caregiverCode.getDeviceID(), false, false);
        caregiverService.deleteCaregiverCode(caregiverCode.getId());

        Device device = deviceService.findById(caregiverCode.getDeviceID());
        String name = device.getCustomName() == null ? "Device #" + device.getId() : device.getCustomName();

        return HttpResponse.ok(Map.of("name", name));
    }

    @Operation(summary = "Generate caregiver's code")
    @Post("/generate/{deviceId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> GenerateCaregiverCode(@PathVariable long deviceId) {
        long userID = authService.getUserID();
        
        if (!deviceUserService.userHasAccessToDevice(userID, deviceId)) {
            return HttpResponse.status(HttpStatus.FORBIDDEN)
                .body(Problem.builder()
                    .withStatus(Status.FORBIDDEN)
                    .withTitle("ACCESS_DENIED")
                    .withDetail("You don't have permission to generate codes for this device")
                    .build());
        }
        
        try {
            DeviceCaregiverCode caregiverCode = caregiverService.generateCaregiverCode(deviceId, userID);
            return HttpResponse.ok(caregiverCode);
        } catch (Exception e) {
            log.atSevere().withCause(e).log("Failed to generate caregiver code for device %d", deviceId);
            return HttpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Problem.builder()
                    .withStatus(Status.INTERNAL_SERVER_ERROR)
                    .withTitle("CODE_GENERATION_FAILED")
                    .withDetail("Failed to generate caregiver code")
                    .build());
        }
    }

    @Operation(summary = "Get share codes for devices")
    @Get("/codes")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> getShareCodes(@QueryValue List<Long> deviceIds) {
        long userID = authService.getUserID();
        
        try {
            List<DeviceCaregiverCodeDTO> shareCodeDTOs = caregiverService.getShareCodesForUser(userID, deviceIds);
            return HttpResponse.ok(shareCodeDTOs);
        } catch (Exception e) {
            log.atSevere().withCause(e).log("Failed to fetch share codes for devices: %s", deviceIds);
            return HttpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Problem.builder()
                    .withStatus(Status.INTERNAL_SERVER_ERROR)
                    .withTitle("FETCH_CODES_FAILED")
                    .withDetail("Failed to fetch share codes")
                    .build());
        }
    }

    @Operation(summary = "Revoke caregiver's access")
    @Post("/revoke/{caregiverId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> RevoqkeCaregiverAccess(@QueryValue long caregiverId) {
        throw new UnsupportedOperationException("Feature incomplete. Contact assistance.");
    }
}