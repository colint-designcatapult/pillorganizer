package jct.pillorganizer.model.device.schedule;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jct.pillorganizer.dto.SimpleScheduleDTO;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.Transient;

/**
 * A simple medication schedule that is the same every day, with one time for AM and one time for PM.
 */
@Entity
@DiscriminatorValue("1")
public class DeviceSimpleScheduleStrategy extends DeviceBaseScheduleStrategy {

    /**
     * Fetches the AM dispense time for this schedule.
     * @return AM dispense time, or null if none exists
     */
    @JsonIgnore
    @Transient
    public DeviceSimpleDispenseTime amTime() {
        return forPeriod('A');
    }

    /**
     * Fetches the PM dispense time for this schedule.
     * @return PM dispense time, or null if none exists
     */
    @JsonIgnore
    @Transient
    public DeviceSimpleDispenseTime pmTime() {
        return forPeriod('P');
    }

    /**
     * Fetches the dispense time for a day period, if one exists.
     * @param period 'A' for AM, 'P' for PM
     * @return dispense time for the specified day period
     */
    @JsonIgnore
    @Transient
    public DeviceSimpleDispenseTime forPeriod(char period) {
        for(DeviceBaseDispenseTime strategy : this.getTimes()) {
            DeviceSimpleDispenseTime simp = (DeviceSimpleDispenseTime) strategy;
            if(simp.getPeriod() == period)
                return simp;
        }
        return null;
    }

    /**
     * Serializes the schedule into a DTO object.
     * @see SimpleScheduleDTO
     * @return a simplified representation of this schedule as a DTO object (POJO)
     */
    @Override
    @JsonIgnore
    @Transient
    public Object buildDTO() {
        Long amID = null, amSecondsFrom00 = null, pmID = null, pmSecondsFrom00 = null;
        for(DeviceBaseDispenseTime strategy : this.getTimes()) {
            DeviceSimpleDispenseTime simp = (DeviceSimpleDispenseTime)strategy;
            if(simp.getPeriod() == 'A') {
                amID = simp.getId();
                amSecondsFrom00 = simp.toSecondsFrom00();
            } else if(simp.getPeriod() == 'P') {
                pmID = simp.getId();
                pmSecondsFrom00 = simp.toSecondsFrom00();
            }
        }
        return new SimpleScheduleDTO(amID, amSecondsFrom00, pmID, pmSecondsFrom00);
    }
}
