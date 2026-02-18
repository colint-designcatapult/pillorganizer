package jct.pillorganizer.tenant.model.user;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.dto.UserRegistration;
import jct.pillorganizer.tenant.serde.HexEncodeSerde;
import lombok.Getter;
import lombok.Setter;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;

/**
 * An `AnonymousUser` is a user who has not formally registered for an account but still needs to be associated with
 * some sort of user for authentication and authorization purposes. This allows customers to make use of the app without
 * having to sign up for a full account. The `secret` is designed to be stored in secure on-device storage and not
 * shared with the user. An anonymous user can be upgraded to a full user.
 * @see jct.pillorganizer.tenant.api.app.AppUserController#upgradeAnonymous(UserRegistration)
 */
@Entity
@DiscriminatorValue("2")
@Getter
@Setter
@Serdeable.Serializable
@Serdeable.Deserializable
public class AnonymousUser extends BaseUser {

    @Column(name = "secret")
    @Serdeable.Serializable(using = HexEncodeSerde.class)
    @Serdeable.Deserializable(using = HexEncodeSerde.class)
    private byte[] secret;

}
