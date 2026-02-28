package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.serde.SerialNumberSerde;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * A pill organizer device.
 */
@MappedEntity("device")
@Getter
@Setter
@Introspected
@Serdeable
public class Device {

    @Id
    private String id;

    private DeviceClass deviceClass = DeviceClass.v1_7x2;

    @Serdeable.Serializable(using = SerialNumberSerde.class)
    private String serialNo;

    private String claimToken;

    @io.micronaut.data.annotation.Version
    @JsonIgnore
    private Long version = 0L;

    private String nickname;

    @Relation(value = Relation.Kind.ONE_TO_MANY, mappedBy = "device")
    @JsonIgnore
    private List<DeviceUser> users;

}
