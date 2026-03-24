package jct.pillorganizer.tenant.model.schedule;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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
    @NotNull
    @Pattern(regexp = "MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY",
             message = "dayOfWeek must be a valid day name (e.g. MONDAY)")
    private String dayOfWeek;

    /** Time of dose in 24-hour HH:mm format, e.g. "08:30" or "20:00". */
    @NotNull
    @Pattern(regexp = "([01]\\d|2[0-3]):[0-5]\\d",
             message = "time must be in HH:mm format (00:00–23:59)")
    private String time;
}
