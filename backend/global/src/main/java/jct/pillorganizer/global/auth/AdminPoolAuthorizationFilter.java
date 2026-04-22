package jct.pillorganizer.global.auth;

import io.micronaut.context.annotation.Value;
import io.micronaut.core.order.Ordered;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.RequestFilter;
import io.micronaut.http.annotation.ServerFilter;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.http.filter.ServerFilterPhase;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AdminGroupExtractor;

@ServerFilter(io.micronaut.http.annotation.Filter.MATCH_ALL_PATTERN)
public class AdminPoolAuthorizationFilter implements Ordered {

    @Inject
    SecurityService securityService;

    @Value("${app.auth.admin.issuer:}")
    String adminIssuer;

    @Value("${app.auth.admin.global-group:admin-global}")
    String globalAdminGroup;

    @RequestFilter
    void filterRequest(HttpRequest<?> request) {
        var auth = securityService.getAuthentication();
        if (auth.isEmpty() || adminIssuer.isBlank()) {
            return;
        }

        if (!isAdminPoolRequest(auth.get())) {
            return;
        }

        if (!AdminGroupExtractor.extract(auth.get()).contains(globalAdminGroup)) {
            throw new HttpStatusException(HttpStatus.FORBIDDEN, "Admin token requires global admin group");
        }
    }

    private boolean isAdminPoolRequest(Authentication authentication) {
        Object issuer = authentication.getAttributes().get("iss");
        return issuer instanceof String && adminIssuer.equals(issuer);
    }

    @Override
    public int getOrder() {
        return ServerFilterPhase.SECURITY.after() - 10;
    }
}
