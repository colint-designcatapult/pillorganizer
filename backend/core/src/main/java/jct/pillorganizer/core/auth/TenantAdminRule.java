package jct.pillorganizer.core.auth;

import io.micronaut.context.annotation.Requires;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.HttpRequest;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import io.micronaut.multitenancy.tenantresolver.TenantResolver;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.rules.SecurityRule;
import io.micronaut.security.rules.SecurityRuleResult;
import jakarta.inject.Singleton;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Mono;

@Requires(
        classes = {HttpRequest.class}
)
@Singleton
public class TenantAdminRule implements SecurityRule<HttpRequest<?>> {

    private final TenantResolver tenantResolver;

    // Constructor injection
    public TenantAdminRule(TenantResolver tenantResolver) {
        this.tenantResolver = tenantResolver;
    }

    @Override
    public int getOrder() {
        return -100; // run before @Secured
    }

    @Override
    public Publisher<SecurityRuleResult> check(HttpRequest<?> request, @Nullable Authentication authentication) {
        if (!authentication.getRoles().contains(AppSecurityRule.IS_ADMIN)) {
            // Only run this rule if an admin is making the request
            return Mono.just(SecurityRuleResult.UNKNOWN);
        }

        if (authentication.getRoles().contains(AppSecurityRule.IS_GLOBAL_ADMIN)) {
            // This user is a global admin. Always allow.
            return Mono.just(SecurityRuleResult.ALLOWED);
        }

        // At this point, the request must be a tenant admin

        try {
            String tenantId = tenantResolver.resolveTenantId();
            if (authentication.getRoles().contains(AppSecurityRule.isTenantAdmin(tenantId))) {
                // Add tenant admin role so it can be picked up by @Secured
                authentication.getRoles().add(AppSecurityRule.IS_TENANT_ADMIN);
                // Allow request to proceed to @Secured filter
                // Make no specific determination
                return Mono.just(SecurityRuleResult.UNKNOWN);
            }
        } catch (TenantNotFoundException ex) {
            // No tenant detected.
            // Tenant admin requests must be scoped to a specific tenant
            return Mono.just(SecurityRuleResult.REJECTED);
        }
        return Mono.just(SecurityRuleResult.REJECTED); // default-deny
    }
}
