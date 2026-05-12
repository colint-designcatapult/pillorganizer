package jct.pillorganizer.tenant.projection;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;

@Introspected
public record DeviceUserAdherenceSummaryView(
        String serialNumber,
        String userId,
        String deviceId,
        long dosesTaken,
        long dosesScheduled,
        @Nullable String subjectId
) {}
