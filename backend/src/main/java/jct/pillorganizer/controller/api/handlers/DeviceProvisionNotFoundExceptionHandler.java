package jct.pillorganizer.controller.api.handlers;

import io.micronaut.context.annotation.Requires;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.server.exceptions.ExceptionHandler;
import io.micronaut.problem.HttpStatusType;
import jakarta.inject.Singleton;
import jct.pillorganizer.exceptions.DeviceProvisionNotFoundException;
import org.zalando.problem.Problem;

import java.net.URI;


@Produces
@Singleton
@Requires(classes = {DeviceProvisionNotFoundException.class, ExceptionHandler.class})
public class DeviceProvisionNotFoundExceptionHandler implements ExceptionHandler<DeviceProvisionNotFoundException, HttpResponse> {

    @Override
    public HttpResponse<Problem> handle(HttpRequest request, DeviceProvisionNotFoundException exception) {
        Problem problem = Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.NOT_FOUND))
                .withType(URI.create(exception.getClass().getSimpleName()))
                .withTitle(exception.getMessage())
                .build();
        return HttpResponse.<Problem>status(HttpStatus.NOT_FOUND).body(problem);
    }
}