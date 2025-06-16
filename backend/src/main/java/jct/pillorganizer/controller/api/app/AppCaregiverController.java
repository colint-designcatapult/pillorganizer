package jct.pillorganizer.controller.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.model.device.DeviceCaregiverCode;
import jct.pillorganizer.service.CaregiverService;
import jct.pillorganizer.service.DeviceUserService;
import lombok.extern.flogger.Flogger;
import org.zalando.problem.Problem;
import org.zalando.problem.Status;

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

    @Operation(summary = "Validate caregiver's code")
    @Post("/validate/{code}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> validateCaregiverCode(@QueryValue long code) {
        long userID = authService.getUserID();
        DeviceCaregiverCode caregiverCode = caregiverService.findCaregiverCode(code);

        if(caregiverCode == null) {
            return HttpResponse.status(HttpStatus.BAD_REQUEST)
                .body(Problem.builder()
                    .withStatus(Status.BAD_REQUEST)
                    .withTitle("INVALID_CAREGIVER_CODE")
                    .withDetail("The provided caregiver code is invalid or has expired: " + code)
                    .build());
        }

        deviceUserService.addUserToDevice(userID, caregiverCode.getDeviceID(), false, false);
        caregiverService.deleteCaregiverCode(caregiverCode.getId());

        return HttpResponse.ok();
    }

    @Operation(summary = "Generate caregiver's code")
    @Post("/generate/{code}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> GenerateCaregiverCode(@QueryValue long code) {
        throw new UnsupportedOperationException("Feature incomplete. Contact assistance.");
    }

    @Operation(summary = "Revoke caregiver's access")
    @Post("/revoke/{caregiverId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> RevoqkeCaregiverAccess(@QueryValue long caregiverId) {
        throw new UnsupportedOperationException("Feature incomplete. Contact assistance.");
    }
}
