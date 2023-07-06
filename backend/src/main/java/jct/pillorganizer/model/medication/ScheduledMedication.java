package jct.pillorganizer.model.medication;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.Device;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.util.Set;

/**
 * A medication that is taken according to some schedule. We currently view a "medication" to be anything you could
 * put in a pill organizer - currently we only really consider pills under this view. A `ScheduledMedication` has a
 * name, shape, color, and a frequency and periodicity.
 */
@Entity(name = "scheduled_medication")
@Getter
@Setter
@Serdeable.Serializable
@Serdeable.Deserializable
public class ScheduledMedication {

    @Id
    @GeneratedValue(strategy= GenerationType.SEQUENCE, generator="scheduled_medication_seq")
    @SequenceGenerator(name = "scheduled_medication_seq", sequenceName = "scheduled_medication_seq", allocationSize = 1)
    private Long id;


    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", referencedColumnName = "id")
    @JsonIgnore
    private Device device;

    @OneToMany(targetEntity = MedicationDispenseTime.class, mappedBy = "medication", fetch = FetchType.LAZY, orphanRemoval = true)
    private Set<MedicationDispenseTime> dispenseTimes;

    @Column(name = "device_id", insertable = false, updatable = false)
    private long deviceID;


    @Column(name = "med_name", nullable = false)
    @Size(min = 1, max = 64)
    @NotBlank
    private String med_name;

    @Column(name = "shape", nullable = true)
    @Enumerated(EnumType.ORDINAL)
    @NotNull
    private MedicationShape shape;

    @Column(name = "color", nullable = true)
    private Integer color;


}
