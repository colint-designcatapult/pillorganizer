package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.*;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.List;
import java.util.UUID;

@MappedEntity("logical_device")
@Getter
@Setter
@Introspected
@Serdeable
public class LogicalDevice {
    @Id
    private String id;

    @Relation(value = Relation.Kind.ONE_TO_MANY, mappedBy = "logicalDevice")
    @JsonIgnore
    private List<ProvisionRecord> provisionRecords;

    @Relation(value = Relation.Kind.ONE_TO_ONE)
    @Nullable
    private ProvisionRecord physicalDevice;

    @Nullable
    private String nickname;

    @Relation(value = Relation.Kind.ONE_TO_MANY, mappedBy = "device")
    @JsonIgnore
    private List<DeviceUser> users;

    /** The currently applied schedule on the device. Null if no schedule has been applied. */
    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @Nullable
    private DeviceSchedule currentSchedule;

    /** The schedule the user wants applied, but hasn't necessarily been confirmed by the device yet. Null if none is pending. */
    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @Nullable
    private DeviceSchedule requestedSchedule;

    @Version
    @JsonIgnore
    private Long version = 0L;

    @DateCreated
    @JsonIgnore
    private Timestamp createdAt;

    @DateUpdated
    @JsonIgnore
    private Timestamp updatedAt;

    @JsonIgnore
    private Timestamp disabledAt = null;
}
