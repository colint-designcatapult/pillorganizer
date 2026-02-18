package jct.pillorganizer.tenant.api.handlers;

import io.micronaut.context.annotation.Requires;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.server.exceptions.ExceptionHandler;
import io.micronaut.problem.HttpStatusType;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.exceptions.AccessForbiddenException;
import org.zalando.problem.Problem;

import java.net.URI;

@Produces
@Singleton
@Requires(classes = {AccessForbiddenException.class, ExceptionHandler.class})
public class AccessForbiddenExceptionHandler implements ExceptionHandler<AccessForbiddenException, HttpResponse<Problem>> {

    @Override
    public HttpResponse<Problem> handle(HttpRequest request, AccessForbiddenException exception) {
        Problem problem = Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.FORBIDDEN))
                .withType(URI.create(exception.getClass().getSimpleName()))
                .withTitle(exception.getMessage())
                .build();
        return HttpResponse.status(HttpStatus.FORBIDDEN).body(problem);
    }
}
