package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

@Introspected
@Serdeable
public record ScheduleBinDto(
        int binIndex,
        String dayOfWeek,
        String genericTime
) {}
