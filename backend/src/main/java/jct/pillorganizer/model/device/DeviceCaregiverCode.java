package jct.pillorganizer.model.device;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.user.BaseUser;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.sql.Timestamp;

/**
 * Device invite codes.
 */
@Entity(name = "device_caregiver_code")
@Table(uniqueConstraints = {
    @UniqueConstraint(columnNames = {"code", "expires_at"},
                     name = "uk_device_caregiver_code_expires")
})
@Getter
@Setter
@Introspected
@Serdeable
public class DeviceCaregiverCode {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "device_code_seq")
    @SequenceGenerator(name = "device_code_seq", sequenceName = "device_code_seq", allocationSize = 1)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", referencedColumnName = "id", insertable = false, updatable = false)
    private BaseUser patient;

    @Column(name = "patient_id")
    private long patientID;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", referencedColumnName = "id", insertable = false, updatable = false)
    private Device device;

    @Column(name = "device_id")
    private long deviceID;

    @Column(name = "code")
    private long code;

    @Column(name = "expires_at")
    private Timestamp expiresAt;

    @Column(name = "deleted")
    private boolean deleted = false;
}