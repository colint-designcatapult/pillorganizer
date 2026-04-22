package jct.pillorganizer.tenant.auth;

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

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

@ServerFilter(io.micronaut.http.annotation.Filter.MATCH_ALL_PATTERN)
public class AdminPoolAuthorizationFilter implements Ordered {

    @Inject
    SecurityService securityService;

    @Value("${app.auth.admin.issuer:}")
    String adminIssuer;

    @Value("${app.auth.admin.global-group:admin-global}")
    String globalAdminGroup;

    @Value("${app.auth.admin.tenant-group:}")
    String tenantAdminGroup;

    @RequestFilter
    void filterRequest(HttpRequest<?> request) {
        var auth = securityService.getAuthentication();
        if (auth.isEmpty() || adminIssuer.isBlank()) {
            return;
        }

        if (!isAdminPoolRequest(auth.get())) {
            return;
        }

        Set<String> groups = extractGroups(auth.get());
        boolean isGlobalAdmin = groups.contains(globalAdminGroup);
        boolean isTenantAdmin = !tenantAdminGroup.isBlank() && groups.contains(tenantAdminGroup);
        if (!isGlobalAdmin && !isTenantAdmin) {
            throw new HttpStatusException(HttpStatus.FORBIDDEN, "Admin token requires global or tenant admin group");
        }
    }

    private boolean isAdminPoolRequest(Authentication authentication) {
        Object issuer = authentication.getAttributes().get("iss");
        return issuer instanceof String && adminIssuer.equals(issuer);
    }

    private Set<String> extractGroups(Authentication authentication) {
        Set<String> groups = new HashSet<>(authentication.getRoles());
        Object claim = authentication.getAttributes().get("cognito:groups");
        if (claim instanceof Collection<?> collection) {
            collection.stream().map(String::valueOf).forEach(groups::add);
        } else if (claim instanceof String value) {
            groups.add(value);
        }
        return groups;
    }

    @Override
    public int getOrder() {
        return ServerFilterPhase.SECURITY.after() - 10;
    }
}
