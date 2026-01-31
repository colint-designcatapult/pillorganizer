package jct.pillorganizer.model.user;

import java.sql.Timestamp;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorColumn;
import jakarta.persistence.DiscriminatorType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.SequenceGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;

import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.DeviceUser;
import lombok.Getter;
import lombok.Setter;

/**
 * A generic human user account that can log in to the system. A BaseUser has a
 * role, which indicates global permissions
 * e.g., administrator. Roles may be indicated in the app's JWT tokens, so use
 * care. A `BaseUser` can be associated with
 * one or more devices, which is the key separation between a user and an
 * `Authenticatable`.
 * 
 * @see Authenticatable
 */
@Entity(name = "users")
@DiscriminatorColumn(name = "user_type", discriminatorType = DiscriminatorType.INTEGER)
@Getter
@Setter
@Serdeable.Serializable
public class BaseUser {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_seq")
    @SequenceGenerator(name = "user_seq", sequenceName = "user_seq", allocationSize = 1)
    private Long id;

    @OneToMany(targetEntity = DeviceUser.class, mappedBy = "user", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<DeviceUser> devices;

    @Column(name = "role")
    @Enumerated(EnumType.ORDINAL)
    private UserRole role;

    @DateCreated
    @Column(name = "created")
    @JsonIgnore
    private Timestamp created;

    @DateUpdated
    @Column(name = "updated")
    @JsonIgnore
    private Timestamp updated;

    @Column(name = "recovery_code")
    @JsonIgnore
    private Long recoveryCode;

    @Column(name = "takecare_patient_id")
    @JsonIgnore
    private String takecarePatientId;
}
