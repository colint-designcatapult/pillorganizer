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
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
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
     * @param deviceId the device ID
     * @return the current scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO getSchedule(String deviceId) {
        LogicalDevice device = logicalDeviceRepository.findById(deviceId)
                .orElseThrow(() -> new DeviceAccessException("Device not found: " + deviceId));

        BaseSchedule current = parseSchedule(device.getCurrentSchedule());
        UUID currentId = device.getCurrentSchedule() != null ? device.getCurrentSchedule().getId() : null;

        BaseSchedule requested = parseSchedule(device.getRequestedSchedule());
        UUID requestedId = device.getRequestedSchedule() != null ? device.getRequestedSchedule().getId() : null;
        ScheduleStatus requestedStatus = device.getRequestedSchedule() != null ? device.getRequestedSchedule().getStatus() : null;

        return new DeviceScheduleStateDTO(currentId, current, requestedId, requested, requestedStatus);
    }

    /**
     * Creates a new PENDING schedule for the device. If a PENDING schedule already exists,
     * it is marked as SUPERSEDED. The new schedule is stored in the database and the device's
     * {@code requestedSchedule} pointer is updated.
     *
     * @param deviceId    the device ID
     * @param newSchedule the new schedule requested by the user
     * @param user        the user making the request
     * @return the updated scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO setSchedule(String deviceId, BaseSchedule newSchedule, ScheduleTakeEffect takeEffect, User user) {
        LogicalDevice device = logicalDeviceRepository.findById(deviceId)
                .orElseThrow(() -> new DeviceAccessException("Device not found: " + deviceId));

        DeviceSchedule existing = device.getRequestedSchedule();
        if (existing != null && existing.getStatus() == ScheduleStatus.PENDING) {
            existing.setStatus(ScheduleStatus.SUPERSEDED);
            deviceScheduleRepository.update(existing);
        }

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

        BaseSchedule current = parseSchedule(device.getCurrentSchedule());
        UUID currentId = device.getCurrentSchedule() != null ? device.getCurrentSchedule().getId() : null;

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
