package jct.pillorganizer.tenant.model.device;

public enum ScheduleTakeEffect {
    /** Apply the schedule to the device immediately. */
    IMMEDIATE,
    /** Apply the schedule on the next medication reload. */
    NEXT_RELOAD
}
