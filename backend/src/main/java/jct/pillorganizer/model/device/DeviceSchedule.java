package jct.pillorganizer.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.time.Instant;

/**
 * Represents the schedule a single bin on a particular pill organizer should follow, such as the day of the week and
 * time of day that particular bin should alert the user to take their pills.
 * @deprecated This is an ugly holdover from a previous system design. Move to using `DeviceBaseScheduleStrategy`
 * directly. Refactoring in progress.
 */
@Entity(name = "device_schedule")
@Getter
@Setter
@Serdeable.Serializable
public class DeviceSchedule {

    @EmbeddedId
    private DeviceBinId id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "device_user_id", referencedColumnName = "id", insertable = false, updatable = false)
    @JsonIgnore
    private DeviceUser deviceUser;

    @Column(name = "day_of_week", nullable = false)
    private DayOfWeek dayOfWeek;

    @Column(name = "seconds_from_00", nullable = false)
    private int secondsFrom00;

    @ManyToOne(optional = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "dispense_time_id", referencedColumnName = "id")
    @JsonIgnore
    private DeviceBaseDispenseTime dispenseTime;

    @io.micronaut.data.annotation.Version
    @JsonIgnore
    private Long version = 0L;

    @DateCreated
    @Column(name = "created_at", nullable = false, updatable = false)
    @JsonIgnore
    private Instant createdAt;

    @DateUpdated
    @Column(name = "updated_at", nullable = false)
    @JsonIgnore
    private Instant updatedAt;

    @Column(name = "deleted_at")
    @JsonIgnore
    private Instant deletedAt;

    public int getBinID() {
        return id.getBinID();
    }


}
