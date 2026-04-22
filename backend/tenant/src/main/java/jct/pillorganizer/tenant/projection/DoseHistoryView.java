package jct.pillorganizer.tenant.projection;

import io.micronaut.core.annotation.Introspected;

import java.time.Instant;

@Introspected
public record DoseHistoryView(
        String logicalDeviceId,
        Long epochWeek,
        Integer binId,
        Instant scheduledTime,
        String finalStatus,
        Instant resolvedTime,
        String deviceTimeZone
) {
}
