package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

import java.time.Instant;
import java.util.List;

@Introspected
@Serdeable
public record WeeklyAdherenceDto(
        String timezone,
        Instant weekStart,
        List<ScheduleBinDto> scheduleBins,
        List<WeeklySlotDto> weekEvents
) {}
