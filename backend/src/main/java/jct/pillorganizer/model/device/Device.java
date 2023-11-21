package jct.pillorganizer.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.model.device.schedule.DeviceBaseScheduleStrategy;
import jct.pillorganizer.model.user.Authenticatable;
import jct.pillorganizer.model.user.UserType;
import jct.pillorganizer.serde.SerialNumberSerde;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;


/**
 * A pill organizer device.
 */
@Entity(name = "device")
@Getter
@Setter
@Introspected
@Serdeable
public class Device implements Authenticatable {

    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="device_seq")
    @SequenceGenerator(name = "device_seq", sequenceName = "device_seq", allocationSize = 1)
    private Long id;

    @Column(name = "device_class", nullable = false)
    private DeviceClass deviceClass = DeviceClass.v1_7x2;

    @Column(name = "serial_no", nullable = false, unique = true)
    @Serdeable.Serializable(using = SerialNumberSerde.class)
    private long serialNo;

    @OneToMany(targetEntity = DeviceEvent.class, mappedBy = "device", fetch = FetchType.LAZY)
    @JsonIgnore
    private Set<DeviceEvent> events;

    @OneToMany(targetEntity = DeviceState.class, mappedBy = "device", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<DeviceState> state;

    @JoinColumn(name = "provision_id", referencedColumnName = "id")
    @OneToOne(fetch = FetchType.LAZY)
    @JsonIgnore
    private DeviceProvision currentProvision;

    @OneToOne(fetch = FetchType.LAZY, mappedBy = "device", orphanRemoval = true, optional = true)
    @JsonIgnore
    @Nullable
    private DeviceBaseScheduleStrategy scheduleStrategy;


    @OneToMany(fetch = FetchType.LAZY, mappedBy = "device")
    @JsonIgnore
    private List<DeviceProvision> provisions;

    @Column(name = "state_hash", nullable = true)
    @JsonIgnore
    private Long stateHash;

    @Column(name = "engr_req")
    @JsonIgnore
    private String engrReq;

    @io.micronaut.data.annotation.Version
    @JsonIgnore
    private Long version = 0L;

    @Column(name = "event_counter", nullable = false)
    @JsonIgnore
    private long eventCounter = 0L;

    @Column(name = "custom_name", nullable = true)
    private String customName;

    @OneToMany(targetEntity = DeviceUser.class, mappedBy = "device", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<DeviceUser> users;

    @Column(name = "last_sync", nullable = true)
    private Timestamp lastSync;

    @Column(name = "ipv4", nullable = true)
    private Integer ipv4;

    @Column(name = "ipv6", nullable = true)
    private byte[] ipv6;

    @Column(name = "base_tz", nullable = true)
    private String baseTZ;

    @Column(name = "battery", nullable = true)
    private Integer battery;

    @Override
    public long getId() {
        return id;
    }

    @Override
    public UserType getUserType() {
        return UserType.DEVICE;
    }

    @JsonIgnore
    @Transient
    public ZoneOffset getTimeZone() {
        if(getBaseTZ() == null) {
            return ZoneOffset.UTC;
        } else {
            // TODO: rethink how to persist timezones to avoid this mess
            return ZoneId.of(getBaseTZ()).getRules().getOffset(Instant.now());
        }
    }


}
