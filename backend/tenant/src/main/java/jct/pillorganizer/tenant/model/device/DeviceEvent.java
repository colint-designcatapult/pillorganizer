package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.EventType;
import lombok.Getter;
import lombok.Setter;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * A single event recorded by a pill organizer device.
 */
@Entity(name = "device_event")
@Getter
@Setter
@Serdeable.Serializable
public class DeviceEvent {

    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="device_event_seq")
    @SequenceGenerator(name = "device_event_seq", sequenceName = "device_event_seq", allocationSize = 1)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "device_user_id", referencedColumnName = "id")
    @JsonIgnore
    private DeviceUser deviceUser;

    @Column(name = "ts", nullable = false)
    private Instant ts;

    @Column(name = "event_type", nullable = false)
    @Enumerated(value = EnumType.ORDINAL)
    private EventType eventType;

    @Column(name = "bin_id", nullable = true)
    private int bin;

}
