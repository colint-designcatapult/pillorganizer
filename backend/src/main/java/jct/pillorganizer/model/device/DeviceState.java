package jct.pillorganizer.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.Version;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import javax.validation.constraints.NotNull;

/**
 * Represents the state of a single "bin" on a particular pill organizer device. The key fields are the status, which
 * indicates whether the bin is scheduled, taken, missed, etc, and the scheduled time, which indicates when that
 * bin is scheduled to be opened. This structure is modelled after the bin state in the firmware.
 */
@Entity(name = "device_state")
@Getter
@Setter
@Serdeable.Serializable
public class DeviceState {

    @EmbeddedId
    private DeviceBinId id;

    @Column(name = "bin_status", nullable = false)
    private BinStatus binStatus;

    @Column(name = "scheduled_time", nullable = false)
    @NotNull
    private long scheduledTime;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "device_user_id", referencedColumnName = "id", insertable = false, updatable = false)
    @JsonIgnore
    private DeviceUser deviceUser;


    @OneToOne(optional = true)
    @JoinColumn(name = "assoc_event_id", referencedColumnName = "id")
    private DeviceEvent event;

    @OneToOne
    @PrimaryKeyJoinColumn
    private DeviceSchedule schedule;

    @ManyToOne(optional = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "dispense_time_id", referencedColumnName = "id")
    @JsonIgnore
    private DeviceBaseDispenseTime dispenseTime;

    @Version
    @JsonIgnore
    private Long version = 0L;

}
