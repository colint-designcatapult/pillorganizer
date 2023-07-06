package jct.pillorganizer.model.device;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Column;
import javax.persistence.Embeddable;
import java.io.Serializable;

/**
 * An identifier referencing a specific bin on a specific pill organizer.
 */
@Embeddable
@Data
@AllArgsConstructor
@NoArgsConstructor
@Serdeable.Serializable
@Introspected
public class DeviceBinId implements Serializable {
    @Column(name = "device_id", nullable = false, updatable = false)
    private long deviceID;
    @Column(name = "bin_id", nullable = false, updatable = false)
    private int binID;

}