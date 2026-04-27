package jct.pillorganizer.core.auth;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Requires;
import io.micronaut.context.annotation.Value;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import io.micronaut.multitenancy.tenantresolver.TenantResolver;
import io.micronaut.security.rules.SecurityRuleResult;
import io.micronaut.security.token.DefaultRolesFinder;
import io.micronaut.security.token.RolesFinder;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Singleton
@Replaces(DefaultRolesFinder.class)
@Requires(bean = TenantResolver.class)
public class CognitoIssuerRolesFinder implements RolesFinder {

    private static final String GROUP_CLAIM = "cognito:groups";

    @Value("${app.auth.admin.issuer}") String adminIssuer;
    @Value("${app.auth.public.issuer}") String publicIssuer;

    @Inject TenantResolver tenantResolver;

    @Override
    public @NonNull List<String> resolveRoles(@Nullable Map<String, Object> attributes) {
        String issuer = (String) attributes.get("iss");

        if (adminIssuer.isBlank()) {
            throw new IllegalArgumentException("Admin issuer not set");
        }

        if (publicIssuer.equals(adminIssuer)) {
            throw new IllegalArgumentException("Admin issuer matches public issuer");
        }

        if (publicIssuer.equals(issuer)) {
            // Fast path: is a normal user
            return List.of(AppSecurityRule.IS_USER);
        } else if (adminIssuer.equals(issuer)) {
            List<String> list = new ArrayList<>();

            // Add admin role
            list.add(AppSecurityRule.IS_ADMIN);

            // Extract the raw groups from the Cognito token
            // Add them as roles
            Object groupsClaim = attributes.get(GROUP_CLAIM);
            if (groupsClaim instanceof List) {
                var presented = (List<String>) groupsClaim;

                // If the user's groups contains the global admin group, ensure
                // it is in their role list
                if (presented.contains(AppSecurityRule.IS_GLOBAL_ADMIN)) {
                    list.add(AppSecurityRule.IS_GLOBAL_ADMIN);
                }

                try {
                    String tenantId = tenantResolver.resolveTenantId();
                    if (presented.contains(AppSecurityRule.isTenantAdmin(tenantId))) {
                        // Add tenant admin role so it can be picked up by @Secured
                        list.add(AppSecurityRule.IS_TENANT_ADMIN);
                    }
                } catch (TenantNotFoundException ex) {
                    // No tenant detected.
                    // Do not add any additional roles.
                }
            }

            return list;
        }

        throw new IllegalStateException("Request did not match any known auth issuer");
    }
}
