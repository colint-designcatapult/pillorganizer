package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.time.Instant;

@Introspected
@Serdeable
public record WeeklySlotDto(
        int binId,
        @Nullable Instant scheduledTime,
        @Nullable String finalStatus,
        @Nullable Instant resolvedTime
) {}
