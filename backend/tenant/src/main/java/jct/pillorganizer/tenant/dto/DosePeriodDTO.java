package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Introspected
@Serdeable.Serializable
public record DosePeriodDTO(short binID, long timestamp, short status, List<Long> medications,
                @Nullable String takenAtTime) {
}
