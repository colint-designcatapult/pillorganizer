package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
import jct.pillorganizer.tenant.model.schedule.SimpleSchedule;

/**
 * Request body for POST /{id}/dispense_time.
 *
 * @param schedule   The new schedule to apply to the device.
 * @param takeEffect When the device should apply the schedule.
 */
@Serdeable
@Introspected
public record SetScheduleRequestDTO(
        SimpleSchedule schedule,
        ScheduleTakeEffect takeEffect
) {}
