package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Introspected
@Serdeable
public record TenantDevicePageDto(
        List<TenantDeviceSummaryDto> items,
        @Nullable String nextCursor
) {}
