package jct.pillorganizer.model.device;

import jct.pillorganizer.proto.Pill;

/**
 * Each day of the week, and an application-specific "DISABLED" day, indicating that the day is to be disregarded.
 */
public enum DayOfWeek {

    // TODO: fix this hack
    DISABLED(1000),     // 1000 is a stupid number to use, we should use a better solution at some point
    MONDAY(0),
    TUESDAY(1),
    WEDNESDAY(2),
    THURSDAY(3),
    FRIDAY(4),
    SATURDAY(5),
    SUNDAY(6);

    private final int val;

    /**
     * Converts a `DayOfWeek` protobuf enum to a Java enum.
     * @param eventType protobuf `DayOfWeek`
     * @return Java `DayOfWeek`
     */
    public static DayOfWeek fromProtobuf(Pill.BinSchedule.DayOfWeek eventType) {
        return fromOrdinal(eventType.getNumber());
    }

    /**
     * Converts a Monday-base DayOfWeek ordinal into an enum.
     * @param ord an integer DayOfWeek value
     * @return java enum
     */
    public static DayOfWeek fromOrdinal(int ord) {
        return switch (ord) {
            case 0 -> MONDAY;
            case 1 -> TUESDAY;
            case 2 -> WEDNESDAY;
            case 3 -> THURSDAY;
            case 4 -> FRIDAY;
            case 5 -> SATURDAY;
            case 6 -> SUNDAY;
            case 1000 -> DISABLED;
            default -> throw new IllegalArgumentException("invalid day of week");
        };
    }

    DayOfWeek(int val) {
        this.val = val;
    }

    /**
     * Converts the `DayOfWeek` into an integer form based on Monday as day zero.
     * @return integer value of the `DayOfWeek` where Monday is the start of the week
     */
    public int getIntValue() {
        return this.val;
    }

}
