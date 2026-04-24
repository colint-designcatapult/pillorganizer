package jct.pillorganizer.core.auth;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Value;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.security.token.DefaultRolesFinder;
import io.micronaut.security.token.RolesFinder;
import jakarta.inject.Singleton;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Singleton
@Replaces(DefaultRolesFinder.class)
public class CognitoIssuerRolesFinder implements RolesFinder {

    private static final String GROUP_CLAIM = "cognito:groups";

    @Value("${app.auth.admin.issuer}") String adminIssuer;

    @Override
    public @NonNull List<String> resolveRoles(@Nullable Map<String, Object> attributes) {
        String issuer = (String) attributes.get("iss");

        if (!adminIssuer.isBlank() && adminIssuer.equals(issuer)) {
            // Extract the raw groups from the Cognito token
            Object groupsClaim = attributes.get(GROUP_CLAIM);
            if (groupsClaim instanceof List) {
                List<String> list = new ArrayList<>((List<String>) groupsClaim);
                list.add(AppSecurityRule.IS_ADMIN);
                return list;
            }
        }

        // Default: return user role (safest)
        return List.of(AppSecurityRule.IS_USER);
    }
}
