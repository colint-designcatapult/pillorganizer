package jct.pillorganizer.model.device.schedule;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.medication.MedicationDispenseTime;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.util.List;

/**
 * A single medication dispense time, for a particular device's schedule. Medications are attached to a dispense time to
 * indicate they should be taken then.
 */
@Entity(name = "device_dispense_time")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name="type",
        discriminatorType = DiscriminatorType.INTEGER)
@Getter
@Setter
@Serdeable.Serializable
public abstract class DeviceBaseDispenseTime {

    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="device_dispense_time_seq")
    @SequenceGenerator(name = "device_dispense_time_seq", sequenceName = "device_dispense_time_seq",
            allocationSize = 1)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id", referencedColumnName = "id", nullable = false)
    @JsonIgnore
    private DeviceBaseScheduleStrategy schedule;

    @OneToMany(targetEntity = MedicationDispenseTime.class, mappedBy = "dispense", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<MedicationDispenseTime> medications;

}
