package jct.pillorganizer.tenant.api.app;

import jct.pillorganizer.core.auth.AppSecurityRule;
import org.zalando.problem.Problem;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.MutableHttpResponse;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.problem.HttpStatusType;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.dto.PatientValidationRequestDTO;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;

@Controller("/api/v1/takecare")
@Flogger
@Secured(AppSecurityRule.IS_USER)
public class AppTakecareController {

    @Operation(summary = "Validate and link a Takecare patient with form data")
    @Post("/validate/{patientID}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<MutableHttpResponse<Object>> validateAndLinkTakecarePatient(
            @PathVariable String patientID,
            @Body PatientValidationRequestDTO validationRequest) {
        throw new RuntimeException("not implemented");
    }
}