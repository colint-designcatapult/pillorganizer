package jct.pillorganizer.tenant.service;

import io.micronaut.serde.ObjectMapper;

import java.io.IOException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.dto.DeviceScheduleStateDTO;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import lombok.extern.flogger.Flogger;

import java.util.UUID;


@Singleton
@Flogger
public class ScheduleService {

    @Inject
    LogicalDeviceRepository logicalDeviceRepository;

    @Inject
    DeviceScheduleRepository deviceScheduleRepository;

    @Inject
    ObjectMapper objectMapper;

    /**
     * Returns the current scheduling state of the device: the applied schedule and any
     * pending requested schedule. If the device has no schedule, all fields are null.
     *
     * @param device the logical device
     * @return the current scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO getSchedule(LogicalDevice device) {
        DeviceSchedule currentSchedule = deviceScheduleRepository
                .findByDeviceIdAndStatus(device.getId(), ScheduleStatus.APPLIED)
                .stream().findFirst().orElse(null);

        DeviceSchedule requestedSchedule = deviceScheduleRepository
                .findByDeviceIdAndStatus(device.getId(), ScheduleStatus.PENDING)
                .stream().findFirst().orElse(null);

        BaseSchedule current = parseSchedule(currentSchedule);
        UUID currentId = currentSchedule != null ? currentSchedule.getId() : null;

        BaseSchedule requested = parseSchedule(requestedSchedule);
        UUID requestedId = requestedSchedule != null ? requestedSchedule.getId() : null;
        ScheduleStatus requestedStatus = requestedSchedule != null ? requestedSchedule.getStatus() : null;

        return new DeviceScheduleStateDTO(currentId, current, requestedId, requested, requestedStatus);
    }

    /**
     * Creates a new PENDING schedule for the device. If a PENDING schedule already exists,
     * it is marked as SUPERSEDED. The new schedule is stored in the database and the device's
     * {@code requestedSchedule} pointer is updated.
     *
     * @param device      the logical device
     * @param newSchedule the new schedule requested by the user
     * @param takeEffect  when the device should apply the schedule
     * @param user        the user making the request
     * @return the updated scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO setSchedule(LogicalDevice device, BaseSchedule newSchedule, ScheduleTakeEffect takeEffect, User user) {
        deviceScheduleRepository.findByDeviceIdAndStatus(device.getId(), ScheduleStatus.PENDING)
                .forEach(existing -> {
                    existing.setStatus(ScheduleStatus.SUPERSEDED);
                    deviceScheduleRepository.update(existing);
                });

        String scheduleJson = serializeSchedule(newSchedule);

        DeviceSchedule pendingSchedule = new DeviceSchedule();
        pendingSchedule.setId(UUID.randomUUID());
        pendingSchedule.setDevice(device);
        pendingSchedule.setScheduleJson(scheduleJson);
        pendingSchedule.setStatus(ScheduleStatus.PENDING);
        pendingSchedule.setTakeEffect(takeEffect);
        pendingSchedule.setCreatedBy(user);

        DeviceSchedule saved = deviceScheduleRepository.save(pendingSchedule);

        device.setRequestedSchedule(saved);
        logicalDeviceRepository.update(device);

        DeviceSchedule currentSchedule = deviceScheduleRepository
                .findByDeviceIdAndStatus(device.getId(), ScheduleStatus.APPLIED)
                .stream().findFirst().orElse(null);
        BaseSchedule current = parseSchedule(currentSchedule);
        UUID currentId = currentSchedule != null ? currentSchedule.getId() : null;

        return new DeviceScheduleStateDTO(currentId, current, saved.getId(), newSchedule, ScheduleStatus.PENDING);
    }

    private BaseSchedule parseSchedule(DeviceSchedule deviceSchedule) {
        if (deviceSchedule == null || deviceSchedule.getScheduleJson() == null) {
            return null;
        }
        try {
            return objectMapper.readValue(deviceSchedule.getScheduleJson(), BaseSchedule.class);
        } catch (IOException e) {
            log.atSevere().withCause(e).log("Failed to parse scheduleJson for device_schedule id=%s", deviceSchedule.getId());
            return null;
        }
    }

    private String serializeSchedule(BaseSchedule schedule) {
        try {
            return objectMapper.writeValueAsString(schedule);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to serialize schedule", e);
        }
    }
}
