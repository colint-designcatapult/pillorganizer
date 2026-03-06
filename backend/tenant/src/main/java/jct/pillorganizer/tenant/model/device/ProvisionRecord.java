package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.data.annotation.*;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.user.BaseUser;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;

@MappedEntity("provision_record")
@Getter
@Setter
@Introspected
@Serdeable
public class ProvisionRecord {
    @Id
    private String claimId;

    private String serialNo;

    private String thingName;

    private DeviceClass deviceClass = DeviceClass.v1_7x2;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @JsonIgnore
    private LogicalDevice logicalDevice;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @JsonIgnore
    private User provisionedBy;

    @DateCreated
    @JsonIgnore
    private Timestamp createdAt;

    @DateUpdated
    @JsonIgnore
    private Timestamp updatedAt;

    private Timestamp disabledAt = null;
}
