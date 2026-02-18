package jct.pillorganizer.global.domain.model;

public record Tenant(
        String tenantId,
        String name,
        String description,
        String apiBase,
        long version
) {
}
