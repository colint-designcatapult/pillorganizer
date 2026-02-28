package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;

@MappedEntity("device_user")
@Getter
@Setter
public class DeviceUser {

    @Id
    private String id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private Device device;

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
