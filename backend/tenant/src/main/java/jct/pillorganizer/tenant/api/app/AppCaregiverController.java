package jct.pillorganizer.tenant.api.app;

import java.util.List;

import io.micronaut.http.HttpResponse;
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
import jct.pillorganizer.tenant.service.DeviceService;
import lombok.extern.flogger.Flogger;

/**
 * API endpoints to interact with caregivers.
 */
@Controller("/api/v1/caregiver")
@Flogger
public class AppCaregiverController {

    @Operation(summary = "Validate caregiver's code")
    @Post("/validate/{code}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> validateCaregiverCode(@PathVariable long code) {
        throw new RuntimeException("not implemented");
    }

    @Operation(summary = "Generate caregiver's code")
    @Post("/generate/{deviceId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> GenerateCaregiverCode(@PathVariable String deviceId) {
        throw new RuntimeException("not implemented");
    }

    @Operation(summary = "Get share codes for devices")
    @Get("/codes")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> getShareCodes(@QueryValue List<String> deviceIds) {
        throw new RuntimeException("not implemented");
    }

    @Operation(summary = "Revoke caregiver's access")
    @Post("/revoke/{caregiverId}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> RevoqkeCaregiverAccess(@QueryValue long caregiverId) {
        throw new UnsupportedOperationException("Feature incomplete. Contact assistance.");
    }
}
