package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;

/**
 * Represents a versioned, immutable schedule for a device.
 * Updates to the schedule create a new row; only the {@code status} and {@code updatedAt}
 * fields are mutable after creation.
 */
@MappedEntity("device_schedule")
@Getter
@Setter
@Introspected
@Serdeable
public class DeviceSchedule {

    @Id
    private String id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @JsonIgnore
    private LogicalDevice device;

    /** Serialized JSON of a {@link jct.pillorganizer.tenant.model.schedule.BaseSchedule}. */
    private String scheduleJson;

    private ScheduleStatus status;

    /** When the device should apply this schedule. */
    private ScheduleTakeEffect takeEffect;

    @DateCreated
    private Timestamp createdAt;

    /**
     * Timestamp of the last status update. Null if the device has not yet processed this schedule.
     * Managed manually — NOT auto-populated — so that null reliably means "awaiting device".
     */
    @Nullable
    private Timestamp updatedAt;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @JsonIgnore
    private User createdBy;
}
