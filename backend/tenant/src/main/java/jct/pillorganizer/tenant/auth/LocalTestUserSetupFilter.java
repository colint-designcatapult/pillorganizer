package jct.pillorganizer.tenant.auth;

import io.micronaut.context.annotation.Requires;
import io.micronaut.core.order.Ordered;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.annotation.RequestFilter;
import io.micronaut.http.annotation.ServerFilter;
import io.micronaut.http.filter.ServerFilterPhase;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.service.UserService;

/**
 * Test-only filter active in the "localtest" environment.
 * Seeds the request with a fixed test user so endpoints that call
 * {@link AuthService#getUser()} work without a real authentication token.
 * This bean is never instantiated in any other environment.
 */
@ServerFilter(io.micronaut.http.annotation.Filter.MATCH_ALL_PATTERN)
@Requires(env = "localtest")
public class LocalTestUserSetupFilter implements Ordered {

    static final String TEST_USER_ID = "test-user-id";

    @Inject
    UserService userService;

    @RequestFilter
    void filterRequest(HttpRequest<?> request) {
        var user = userService.ensureExists(TEST_USER_ID);
        request.setAttribute(UserFilter.USER_ID_ATTRIBUTE, TEST_USER_ID);
        request.setAttribute(UserFilter.USER_ENTITY_ATTRIBUTE, user);
    }

    @Override
    public int getOrder() {
        return ServerFilterPhase.SECURITY.after() + 1; // Run just after UserFilter
    }
}
