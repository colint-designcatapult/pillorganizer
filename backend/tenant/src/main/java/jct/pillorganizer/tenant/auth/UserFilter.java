package jct.pillorganizer.tenant.auth;

import io.micronaut.core.order.Ordered;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.annotation.RequestFilter;
import io.micronaut.http.annotation.ServerFilter;
import io.micronaut.http.filter.ServerFilterPhase;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.exceptions.InvalidTenantUserException;
import jct.pillorganizer.tenant.model.user.BaseUser;
import jct.pillorganizer.tenant.service.UserService;

@ServerFilter(io.micronaut.http.annotation.Filter.MATCH_ALL_PATTERN)
public class UserFilter implements Ordered {

    public static final String USER_ID_ATTRIBUTE = "userId";
    public static final String USER_ENTITY_ATTRIBUTE = "userEntity";

    @Inject
    SecurityService securityService;

    @Inject
    UserService userService;

    @RequestFilter
    void filterRequest(HttpRequest<?> request) {
        String userIdString = securityService.getAuthentication()
                .orElseThrow(() -> new AuthenticationException("No authentication provided"))
                .getAttributes()
                .get("userId")
                .toString();

        request.setAttribute(USER_ID_ATTRIBUTE, userIdString);

        BaseUser user = userService.ensureExists(userIdString);
        request.setAttribute(USER_ENTITY_ATTRIBUTE, user);
    }

    @Override
    public int getOrder() {
        return ServerFilterPhase.SECURITY.after();
    }
}
