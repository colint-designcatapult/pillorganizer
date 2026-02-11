package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

/**
 * A simplified representation of a "DeviceSimpleScheduleStrategy" and two "DeviceSimpleDispenseTime" objects, hiding
 * the underlying complexity of the data structure.
 * @param amID ID of the AM dispense time
 * @param amSecondsFrom00 AM dispense time in day-epoch format (seconds)
 * @param pmID ID of the PM dispense time
 * @param pmSecondsFrom00 PM dispense time in day-epoch format (seconds)
 */
@Serdeable.Serializable
@Serdeable.Deserializable
@Introspected
public record SimpleScheduleDTO(@Nullable Long amID, @Nullable Long amSecondsFrom00,
                                @Nullable Long pmID, @Nullable Long pmSecondsFrom00) {

    public static final SimpleScheduleDTO EMPTY = new SimpleScheduleDTO(null, null, null, null);

    /**
     * Returns a simple schedule with all fields set to null, representing an empty schedule.
     * @return an empty DTO
     */
    public static SimpleScheduleDTO empty() {
        return EMPTY;
    }

}
