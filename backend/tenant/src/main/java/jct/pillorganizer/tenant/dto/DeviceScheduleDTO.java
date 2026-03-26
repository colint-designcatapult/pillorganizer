package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;

import java.util.UUID;

@Serdeable
@Introspected
public record DeviceScheduleDTO(UUID id, ScheduleTakeEffect takeEffect, BaseSchedule schedule) {
}
