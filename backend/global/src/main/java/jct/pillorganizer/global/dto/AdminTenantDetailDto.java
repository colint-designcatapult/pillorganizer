package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.TenantDetails;

@Serdeable.Serializable
public record AdminTenantDetailDto(
        String id,
        String name,
        String hostname,
        boolean active
) {
    public static AdminTenantDetailDto from(TenantDetails tenant) {
        return new AdminTenantDetailDto(
                tenant.getId(),
                tenant.getName() != null ? tenant.getName() : tenant.getId(),
                tenant.getHostname(),
                tenant.isActive()
        );
    }
}
