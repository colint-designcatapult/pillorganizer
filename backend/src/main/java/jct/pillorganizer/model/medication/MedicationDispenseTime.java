package jct.pillorganizer.model.medication;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

/**
 * Relates a `ScheduledMedication` to a `DeviceBaseDispenseTime`. Also contains the quantity of medication to be taken
 * at a given dispense time.
 * @see ScheduledMedication
 * @see DeviceBaseDispenseTime
 */
@Entity(name = "medication_dispense_time")
@Table(
        name = "medication_dispense_time",
        uniqueConstraints = {
                @UniqueConstraint(name = "medication_dispense_time_unique", columnNames = { "medication_id", "dispense_id" })
        }
)
@Getter
@Setter
@Serdeable.Serializable
@Serdeable.Deserializable
public class MedicationDispenseTime {

    @Id
    @GeneratedValue(strategy= GenerationType.SEQUENCE, generator="medication_dispense_time_seq")
    @SequenceGenerator(name = "medication_dispense_time_seq", sequenceName = "medication_dispense_time_seq", allocationSize = 1)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "medication_id", referencedColumnName = "id", insertable = false, updatable = false)
    @JsonIgnore
    private ScheduledMedication medication;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "dispense_id", referencedColumnName = "id", insertable = false, updatable = false)
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private DeviceBaseDispenseTime dispense;

    @Column(name = "medication_id")
    private long medicationID;

    @Column(name = "dispense_id")
    private long dispenseID;

    @Column(name = "quantity")
    private int quantity;

}
