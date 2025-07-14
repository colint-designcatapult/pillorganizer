package jct.pillorganizer.controller.api.app;

import org.zalando.problem.Problem;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.MutableHttpResponse;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.problem.HttpStatusType;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.service.TakecareService;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;

@Controller("/api/v1/takecare")
@Flogger
public class AppTakecareController {
    
    @Inject
    TakecareService takecareService;

    @Operation(summary = "Link a Takecare patient")
    @Post("/link/{patientID}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<MutableHttpResponse<Object>> linkTakecarePatient(@PathVariable String patientID) {
        return takecareService.linkTakecarePatient(patientID)
                .map(ignored -> HttpResponse.ok())
                .onErrorResume(throwable -> {
                    if (throwable instanceof Problem) {
                        return Mono.error(throwable);
                    } else {
                        log.atSevere().withCause(throwable).log("Error validating patient: %s", patientID);
                        return Mono.error(Problem.builder()
                                .withStatus(new HttpStatusType(HttpStatus.INTERNAL_SERVER_ERROR))
                                .build());
                    }
                });
    }
}
