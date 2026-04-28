package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import java.time.Instant;

@Introspected
@Serdeable
public record DoseHistoryDto(
        String logicalDeviceId,
        Instant epochWeek,
        Integer binId,
        Instant scheduledTime,
        String finalStatus,
        Instant resolvedTime,
        String deviceTimeZone
) {
}
