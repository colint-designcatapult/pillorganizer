package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.serde.SerialNumberSerde;
import lombok.Getter;
import lombok.Setter;

import jakarta.persistence.*;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;

/**
 * A pill organizer device.
 */
@Entity(name = "device")
@Getter
@Setter
@Introspected
@Serdeable
public class Device {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "device_seq")
    @SequenceGenerator(name = "device_seq", sequenceName = "device_seq", allocationSize = 1)
    private Long id;

    @Column(name = "device_class", nullable = false)
    private DeviceClass deviceClass = DeviceClass.v1_7x2;

    @Column(name = "serial_no", nullable = false, unique = true)
    @Serdeable.Serializable(using = SerialNumberSerde.class)
    private long serialNo;

    @JoinColumn(name = "provision_id", referencedColumnName = "id")
    @OneToOne(fetch = FetchType.LAZY)
    @JsonIgnore
    private DeviceProvision currentProvision;

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

    @Column(name = "charging", nullable = false)
    private boolean charging;

    @Column(name = "engr_data", nullable = true, columnDefinition = "jsonb")
    private String engr_data;


    @JsonIgnore
    @Transient
    public ZoneOffset getTimeZone() {
        if (getBaseTZ() == null) {
            return ZoneOffset.UTC;
        } else {
            // TODO: rethink how to persist timezones to avoid this mess
            return ZoneId.of(getBaseTZ()).getRules().getOffset(Instant.now());
        }
    }

}
