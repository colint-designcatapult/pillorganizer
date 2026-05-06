package jct.pillorganizer.tenant.projection;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;

import java.time.Instant;

@Introspected
public record WeeklyEventView(
        int binId,
        @Nullable Instant scheduledTime,
        String finalStatus,
        @Nullable Instant resolvedTime
) {}
