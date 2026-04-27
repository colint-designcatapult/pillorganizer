package jct.pillorganizer.global.controller;

import io.micronaut.context.annotation.Requires;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.server.exceptions.ExceptionHandler;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import io.micronaut.problem.HttpStatusType;
import jakarta.inject.Singleton;
import org.zalando.problem.Problem;

import java.net.URI;

@Produces
@Singleton
@Requires(classes = {TenantNotFoundException.class, ExceptionHandler.class})

public class TenantNotFoundExceptionHandler implements ExceptionHandler<TenantNotFoundException, HttpResponse> {
    @Override
    public HttpResponse handle(HttpRequest request, TenantNotFoundException exception) {
        Problem problem = Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.NOT_FOUND))
                .withType(URI.create(exception.getClass().getSimpleName()))
                .withTitle(exception.getMessage())
                .build();
        return HttpResponse.<Problem>status(HttpStatus.NOT_FOUND).body(problem);
    }
}
