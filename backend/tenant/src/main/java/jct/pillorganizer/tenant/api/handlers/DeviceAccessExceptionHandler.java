package jct.pillorganizer.tenant.api.handlers;

import io.micronaut.context.annotation.Requires;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Produces;
import io.micronaut.http.server.exceptions.ExceptionHandler;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.exceptions.InvalidTenantUserException;
import org.zalando.problem.Problem;

@Produces
@Requires(classes = { InvalidTenantUserException.class, ExceptionHandler.class })
@Singleton
public class DeviceAccessExceptionHandler implements ExceptionHandler<DeviceAccessException, HttpResponse<?>> {
    @Override
    public HttpResponse<?> handle(HttpRequest request, DeviceAccessException exception) {
        return HttpResponse.notFound()
                .body(Problem.builder()
                        .withTitle(exception.getMessage())
                        .build());
    }
}
