package jct.pillorganizer.tenant.model.medication;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import lombok.Getter;
import lombok.Setter;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
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
    @JoinColumn(name = "device_user_id", referencedColumnName = "id")
    @JsonIgnore
    private DeviceUser deviceUser;

    @OneToMany(targetEntity = MedicationDispenseTime.class, mappedBy = "medication", fetch = FetchType.LAZY, orphanRemoval = true)
    private Set<MedicationDispenseTime> dispenseTimes;

    @Column(name = "device_user_id", insertable = false, updatable = false)
    private long device_user_id;


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
}
