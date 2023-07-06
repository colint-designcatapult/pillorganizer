package jct.pillorganizer.model.device.schedule;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.Device;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.util.Set;

/**
 * An abstract device schedule. A device schedule has zero or more "dispense times", indicating when medication should
 * be dispensed on a device. This class is abstract to possibly support different scheduling styles, i.e., once a day or
 * every other day.
 */
@Entity(name = "device_schedule_strategy")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name="type",
        discriminatorType = DiscriminatorType.INTEGER)
@Getter
@Setter
@Serdeable.Serializable
@Serdeable.Deserializable
public abstract class DeviceBaseScheduleStrategy {

    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="device_schedule_strategy_seq")
    @SequenceGenerator(name = "device_schedule_strategy_seq", sequenceName = "device_schedule_strategy_seq",
            allocationSize = 1)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", referencedColumnName = "id", nullable = false)
    @JsonIgnore
    private Device device;

    @OneToMany(targetEntity = DeviceBaseDispenseTime.class, mappedBy = "schedule", fetch = FetchType.LAZY)
    private Set<DeviceBaseDispenseTime> times;

    /**
     * Converts the schedule into a data transfer object for JSON serialization.
     * @see DeviceSimpleScheduleStrategy#buildDTO()
     * @return a DTO of this schedule
     */
    @JsonIgnore
    @Transient
    // TODO: type-safe return type
    public abstract Object buildDTO();

}
