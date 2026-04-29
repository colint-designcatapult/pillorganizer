package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.serde.annotation.Serdeable;
import java.util.List;

@Introspected
@Serdeable
public record MonthDaysWithDataDto(
        Integer year,
        Integer month,
        @NonNull
        List<Integer> daysWithData
) {
}
