package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.schedule.SimpleSchedule;

import java.util.UUID;

/**
 * Represents the current scheduling state of a device.
 *
 * @param currentScheduleId   ID of the currently applied schedule, or null if none.
 * @param currentSchedule     The currently applied schedule, or null if none.
 * @param requestedScheduleId ID of the pending requested schedule, or null if none.
 * @param requestedSchedule   The pending requested schedule, or null if none.
 * @param requestedStatus     Status of the requested schedule (PENDING, REJECTED, etc.), or null if none.
 */
@Serdeable
@Introspected
public record DeviceScheduleStateDTO(
        @Nullable UUID currentScheduleId,
        @Nullable SimpleSchedule currentSchedule,
        @Nullable UUID requestedScheduleId,
        @Nullable SimpleSchedule requestedSchedule,
        @Nullable ScheduleStatus requestedStatus
) {}
