package jct.pillorganizer.global.dto;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.TenantDetails;

@Serdeable.Serializable
public record AdminTenantSummaryDto(
        String id,
        String name,
        String hostname,
        boolean active
) {
    public static AdminTenantSummaryDto from(TenantDetails tenant) {
        return new AdminTenantSummaryDto(
                tenant.getId(),
                tenant.getName() != null ? tenant.getName() : tenant.getId(),
                tenant.getHostname(),
                tenant.isActive()
        );
    }
}
