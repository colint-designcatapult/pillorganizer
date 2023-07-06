package jct.pillorganizer.model.user;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.DiscriminatorValue;
import javax.persistence.Entity;

/**
 * A standard user account with an email/password combo. Users of this type are intended to be humans who explicitly
 * registered for a CabiNET account and voluntarily supplied their own email and password. 
 */
@Entity
@DiscriminatorValue("1")
@Getter
@Setter
@Serdeable.Serializable
public class User extends BaseUser {

    @Column(unique = true)
    private String email;

    @Column(name = "password_hash")
    @JsonIgnore
    private byte[] passwordHash;
}
