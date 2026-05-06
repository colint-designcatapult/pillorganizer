package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

@Introspected
@Serdeable
public record TenantDeviceSummaryDto(
        String deviceId,
        @Nullable String serialNumber,
        String userId,
        int subjectId,
        long dosesTaken,
        long dosesScheduled
) {}
