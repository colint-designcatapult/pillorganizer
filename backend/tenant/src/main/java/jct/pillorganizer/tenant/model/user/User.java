package jct.pillorganizer.tenant.model.user;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.*;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.List;

/**
 * A standard user account with an email/password combo. Users of this type are intended to be humans who explicitly
 * registered for a CabiNET account and voluntarily supplied their own email and password. 
 */
@MappedEntity("users")
@Getter
@Setter
@Serdeable.Serializable
public class User {

    @Id
    private String id;

    @NotNull
    private UserType userType;

    @DateCreated
    @JsonIgnore
    private Timestamp created;

    @DateUpdated
    @JsonIgnore
    private Timestamp updated;

    @Relation(value = Relation.Kind.ONE_TO_MANY, mappedBy = "user")
    @JsonIgnore
    private List<DeviceUser> devices;

    private String name;

    private String email;

}
