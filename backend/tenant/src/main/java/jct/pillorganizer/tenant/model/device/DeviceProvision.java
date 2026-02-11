package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.data.annotation.DateCreated;
import io.micronaut.data.annotation.DateUpdated;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.user.BaseUser;
import jct.pillorganizer.tenant.serde.HexEncodeSerde;
import lombok.Getter;
import lombok.Setter;

import jakarta.persistence.*;
import java.sql.Timestamp;

/**
 * A record of a particular attempt at provisioning a pill organizer device, regardless of it was successful or not.
 * This is essentially a "session" record of a provision attempt. A device can potentially have many different
 * provision records.
 */
@Entity(name = "device_provision")
@Getter
@Setter
@Serdeable.Serializable
public class DeviceProvision {

    @Id
    @GeneratedValue(strategy= GenerationType.SEQUENCE, generator="device_provision_seq")
    @SequenceGenerator(name = "device_provision_seq", sequenceName = "device_provision_seq", allocationSize = 1)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", referencedColumnName = "id", nullable = false)
    @JsonIgnore
    private Device device;

    @Column(name = "active")
    private boolean active = false;

    @Column(name = "oob_key")
    @Serdeable.Serializable(using = HexEncodeSerde.class)
    private byte[] oobKey;

    @Column(name = "bssid")
    @JsonIgnore
    private String bssid;

    @Column(name = "ssid")
    @JsonIgnore
    private String ssid;

    @io.micronaut.data.annotation.Version
    @JsonIgnore
    private Long version = 0L;

    @JsonIgnore
    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false, insertable = false, updatable = false)
    private BaseUser user;

    @Column(name = "user_id")
    private long userID;

    @DateCreated
    @Column(name = "created")
    @JsonIgnore
    private Timestamp created;

    @DateUpdated
    @Column(name = "updated")
    @JsonIgnore
    private Timestamp updated;

    @Column(name = "timezone")
    private String timezone;

}
