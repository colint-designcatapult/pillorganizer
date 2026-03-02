package jct.pillorganizer.tenant.model.user;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * A standard user account with an email/password combo. Users of this type are intended to be humans who explicitly
 * registered for a CabiNET account and voluntarily supplied their own email and password. 
 */
@MappedEntity("users")
@Getter
@Setter
@Serdeable.Serializable
public class User extends BaseUser {

    @Relation(value = Relation.Kind.ONE_TO_MANY, mappedBy = "user")
    @JsonIgnore
    private List<DeviceUser> devices;

    private String name;

    private String email;

}
