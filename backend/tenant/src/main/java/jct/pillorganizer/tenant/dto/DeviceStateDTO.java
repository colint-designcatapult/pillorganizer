package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.Date;
import java.util.List;

@Introspected
@Serdeable.Serializable
public record DeviceStateDTO(long id, @Nullable Date lastSync, long bins, List<DosePeriodDTO> dosePeriods,
                Integer battery, boolean charging) {
}
