package jct.pillorganizer.model.user;

import java.sql.Timestamp;
import java.util.List;

import javax.persistence.Column;
import javax.persistence.DiscriminatorColumn;
import javax.persistence.DiscriminatorType;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import javax.persistence.SequenceGenerator;

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

    @Column(name = "patient_id")
    @JsonIgnore
    private String patientId;
}
