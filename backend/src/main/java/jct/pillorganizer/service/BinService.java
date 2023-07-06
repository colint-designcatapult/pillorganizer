package jct.pillorganizer.service;

import jakarta.inject.Singleton;
import jct.pillorganizer.model.device.DayOfWeek;
import jct.pillorganizer.model.device.DeviceClass;

/**
 * Service for dealing with bins and bin IDs on devices.
 */
@Singleton
public class BinService {

    /**
     * Finds the bin ID for the given specification. For example, this can convert (MONDAY, 'A') into bin ID 1.
     * @param deviceClass type of device
     * @param dayOfWeek day of the week
     * @param period period of the day, 'A' for AM and 'P' for PM
     * @return best bin ID for the given parameters
     */
    public int getBinID(DeviceClass deviceClass, DayOfWeek dayOfWeek, char period) {
        if(deviceClass != DeviceClass.v1_7x2)
            throw new IllegalArgumentException("Unsupported device class");
        int bin = switch (dayOfWeek) {
            case MONDAY -> 0;
            case TUESDAY -> 2;
            case WEDNESDAY -> 4;
            case THURSDAY -> 6;
            case FRIDAY -> 8;
            case SATURDAY -> 10;
            case SUNDAY -> 12;
            case DISABLED -> throw new IllegalArgumentException("Cannot use disabled DOW");
        };
        if(period == 'A') {
            bin++;
        }
        return bin;

    }


}
