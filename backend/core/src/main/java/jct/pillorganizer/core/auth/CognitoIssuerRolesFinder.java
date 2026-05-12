package jct.pillorganizer.core.auth;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Value;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import io.micronaut.multitenancy.tenantresolver.TenantResolver;
import io.micronaut.security.rules.SecurityRuleResult;
import io.micronaut.security.token.Claims;
import io.micronaut.security.token.DefaultRolesFinder;
import io.micronaut.security.token.RolesFinder;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.service.TenantService;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Singleton
@Replaces(DefaultRolesFinder.class)
public class CognitoIssuerRolesFinder implements RolesFinder {

    private static final String GROUP_CLAIM = "cognito:groups";

    @Value("${app.auth.admin.issuer}") String adminIssuer;
    @Value("${app.auth.public.issuer}") String publicIssuer;

    @Inject Optional<TenantResolver> tenantResolver;
    @Inject TenantService tenantService;

    @Override
    public @NonNull List<String> resolveRoles(@Nullable Map<String, Object> attributes) {
        // If no attributes, return empty role list
        if (attributes == null || attributes.isEmpty()) {
            return List.of();
        }

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
                for (TenantDetails details : tenantService.getTenantList()) {
                    String tenantAdminRole = AppSecurityRule.isTenantAdmin(details.getId());
                    if (presented.contains(tenantAdminRole)) {
                        list.add(tenantAdminRole);
                    }
                }

                if (tenantResolver.isPresent()) {
                    try {
                        String tenantId = tenantResolver.get().resolveTenantId();
                        if (presented.contains(AppSecurityRule.isTenantAdmin(tenantId))) {
                            list.add(AppSecurityRule.IS_TENANT_ADMIN);
                        }

                        if (list.contains(AppSecurityRule.IS_GLOBAL_ADMIN)) {
                            list.add(AppSecurityRule.IS_TENANT_ADMIN);
                        }
                    } catch (TenantNotFoundException ex) {
                        // No tenant detected.
                    }
                } else if (list.contains(AppSecurityRule.IS_GLOBAL_ADMIN)) {
                    list.add(AppSecurityRule.IS_TENANT_ADMIN);
                }
            }

            return list;
        }

        throw new IllegalStateException("Request did not match any known auth issuer");
    }
}
