package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.TenantDetails;

import java.util.Collection;
import java.util.List;

@Serdeable.Serializable
public record UserDetailsDto(
        String sub,
        Collection<String> roles,
        @Nullable String userId,
        @Nullable String email,
        @Nullable String displayName,
        @Nullable Collection<TenantDetails> tenants
        ) {
}
