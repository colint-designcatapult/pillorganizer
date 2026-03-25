package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;

import java.util.UUID;

/**
 * Represents the current scheduling state of a device.
 *
 * @param currentSchedule     The currently applied schedule, or null if none.
 * @param requestedSchedule   The pending requested schedule, or null if none.
 * @param requestedStatus     Status of the requested schedule (PENDING, REJECTED, etc.), or null if none.
 */
@Serdeable
@Introspected
public record DeviceScheduleStateDTO(
        @Nullable DeviceScheduleDTO currentSchedule,
        @Nullable DeviceScheduleDTO requestedSchedule,
        @Nullable ScheduleStatus requestedStatus
) {}
