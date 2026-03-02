package jct.pillorganizer.tenant.model.user;

import java.sql.Timestamp;

import io.micronaut.data.annotation.*;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import com.fasterxml.jackson.annotation.JsonIgnore;


@MappedEntity("users")
@Getter
@Setter
@Serdeable.Serializable
public class BaseUser {
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
}
