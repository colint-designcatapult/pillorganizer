package jct.pillorganizer.core.auth;

import io.micronaut.security.authentication.Authentication;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

public final class AdminGroupExtractor {

    private AdminGroupExtractor() {
    }

    public static Set<String> extract(Authentication authentication) {
        Set<String> groups = new HashSet<>(authentication.getRoles());
        Object claim = authentication.getAttributes().get("cognito:groups");
        if (claim instanceof Collection<?> collection) {
            collection.stream().map(String::valueOf).forEach(groups::add);
        } else if (claim instanceof String value) {
            groups.add(value);
        }
        return groups;
    }
}
