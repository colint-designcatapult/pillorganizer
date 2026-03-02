package jct.pillorganizer.tenant.api.handlers;

import io.micronaut.context.annotation.Requires;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.server.exceptions.ExceptionHandler;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.exceptions.InvalidTenantUserException;
import org.zalando.problem.Problem;

@Produces
@Requires(classes = { InvalidTenantUserException.class, ExceptionHandler.class })
@Singleton
public class InvalidTenantUserExceptionHandler implements ExceptionHandler<InvalidTenantUserException, HttpResponse<?>> {
    @Override
    public HttpResponse<?> handle(HttpRequest request, InvalidTenantUserException exception) {
        return HttpResponse.unauthorized()
                .body(Problem.builder()
                        .withTitle(exception.getMessage())
                        .build());
    }
}
