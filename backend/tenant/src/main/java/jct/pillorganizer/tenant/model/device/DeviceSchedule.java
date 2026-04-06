package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.UUID;

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
    private UUID id;

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

    @DateUpdated
    private Timestamp updatedAt;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @JsonIgnore
    private User createdBy;

    /** IANA timezone identifier, e.g. {@code America/New_York}. */
    @Nullable
    private String timezoneIana;

    /** POSIX TZ string derived from {@link #timezoneIana}, e.g. {@code EST5EDT,M3.2.0,M11.1.0}. */
    @Nullable
    private String timezonePosix;
}
