package jct.pillorganizer.tenant.model.device;

import java.sql.Timestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.user.BaseUser;
import lombok.Getter;
import lombok.Setter;

/**
 * Device invite codes.
 */
@Entity(name = "device_caregiver_code")
@Table(uniqueConstraints = {
    @UniqueConstraint(columnNames = {"code", "expires_at"},
                     name = "uk_device_caregiver_code_expires"),
    @UniqueConstraint(columnNames = {"code"},
                     name = "uk_device_caregiver_code_unique")
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