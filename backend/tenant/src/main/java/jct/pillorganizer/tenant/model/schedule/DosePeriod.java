package jct.pillorganizer.tenant.model.schedule;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

/**
 * Represents a single scheduled dose for a given day and time.
 * Maps directly to one physical bin on the device (day + morning/evening icon).
 */
@Serdeable
@Introspected
@Getter
@Setter
public class DosePeriod {

    /** Day of the week, e.g. "MONDAY", "TUESDAY". */
    private String dayOfWeek;

    /** Time of dose in 24-hour HH:mm format, e.g. "08:30" or "20:00". */
    private String time;
}
