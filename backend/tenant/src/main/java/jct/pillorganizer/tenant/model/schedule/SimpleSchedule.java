package jct.pillorganizer.tenant.model.schedule;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * A simple schedule: zero, once, or twice daily per day of the week.
 * Each entry in {@code bins} corresponds to one physical bin on the device.
 * Bins with no medication are omitted from the array.
 */
@Serdeable
@Introspected
@Getter
@Setter
public class SimpleSchedule implements BaseSchedule {

    /** The scheduled dose periods. Only bins with medication should be included. */
    private List<DosePeriod> bins;

    @Override
    @JsonProperty(access = JsonProperty.Access.READ_ONLY)
    public String getType() {
        return "SIMPLE";
    }
}
