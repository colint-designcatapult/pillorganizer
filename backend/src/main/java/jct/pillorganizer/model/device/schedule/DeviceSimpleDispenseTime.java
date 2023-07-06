package jct.pillorganizer.model.device.schedule;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.serde.CharEncodeSerde;
import jct.pillorganizer.serde.LocalTimeEncodeSerde;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.DiscriminatorValue;
import javax.persistence.Entity;
import javax.persistence.Transient;
import java.time.LocalTime;

/**
 * A simple dispense time with a time and day period.
 */
@Entity
@DiscriminatorValue("1")
@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
@Getter
@Setter
public class DeviceSimpleDispenseTime extends DeviceBaseDispenseTime {

    @Column(name = "time")
    @Serdeable.Serializable(using = LocalTimeEncodeSerde.class)
    @Serdeable.Deserializable(using = LocalTimeEncodeSerde.class)
    private LocalTime time;

    /**
     * The period of the day to schedule on. This determines whether this is scheduled on an AM bin or PM bin. Set to
     * 'A' for AM and 'P' for PM.
     */
    @Column(name = "period")
    @Serdeable.Serializable(using = CharEncodeSerde.class)
    @Serdeable.Deserializable(using = CharEncodeSerde.class)
    // TODO: refactor to use enum
    private char period;

    /**
     * Converts the dispense time into day-epoch seconds.
     * @return the dispense time as the number of seconds from midnight, UTC
     */
    @Transient
    public long toSecondsFrom00() {
        return time.getSecond() + time.getMinute() * 60 + time.getHour() * 3600;
    }

}
