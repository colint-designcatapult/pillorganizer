package jct.pillorganizer.tenant.model.user;

import java.sql.Timestamp;

import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;
import com.fasterxml.jackson.annotation.JsonIgnore;

/**
 * A generic human user account that can log in to the system. A BaseUser has a
 * role, which indicates global permissions
 * e.g., administrator. Roles may be indicated in the app's JWT tokens, so use
 * care. A `BaseUser` can be associated with
 * one or more devices, which is the key separation between a user and an
 * `Authenticatable`.
 **/
@MappedEntity("users")
@Getter
@Setter
@Serdeable.Serializable
public class BaseUser {

    @Id
    private String id;

    @DateCreated
    @JsonIgnore
    private Timestamp created;

    @DateUpdated
    @JsonIgnore
    private Timestamp updated;
}
