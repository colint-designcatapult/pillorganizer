package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotBlank;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;

/**
 * Request body for POST /{id}/schedule.
 *
 * @param schedule      The new schedule to apply to the device.
 * @param takeEffect    When the device should apply the schedule.
 * @param timezoneIana  IANA timezone identifier for the device (e.g. {@code America/Toronto}).
 */
@Serdeable
@Introspected
public record SetScheduleRequestDTO(
        BaseSchedule schedule,
        ScheduleTakeEffect takeEffect,
        @NotBlank String timezoneIana
) {}
