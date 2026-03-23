package jct.pillorganizer.tenant.model.device;

public enum ScheduleStatus {
    /** Schedule change requested by user but not yet processed by device. */
    PENDING,
    /** Schedule change accepted and applied by device. */
    APPLIED,
    /** Schedule change rejected by device. */
    REJECTED,
    /** A newer schedule was applied by the device; this one is obsolete. */
    SUPERSEDED
}
