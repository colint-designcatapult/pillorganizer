package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.data.annotation.*;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.UUID;

@MappedEntity("device_user")
@Getter
@Setter
@Introspected
public class DeviceUser {
    @Id
    private UUID id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private LogicalDevice device;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private User user;

    private boolean primaryUser;

    @DateCreated
    @JsonIgnore
    private Timestamp createdAt;

    @DateUpdated
    @JsonIgnore
    private Timestamp updatedAt;

}
