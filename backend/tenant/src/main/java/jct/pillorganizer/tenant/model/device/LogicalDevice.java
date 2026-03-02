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
    private UUID id;

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
