package jct.pillorganizer.tenant.service;

import io.micronaut.serde.ObjectMapper;

import java.io.IOException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.dto.DeviceScheduleDTO;
import jct.pillorganizer.tenant.dto.DeviceScheduleStateDTO;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect;
import jct.pillorganizer.tenant.model.schedule.BaseSchedule;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.iotdataplane.model.ResourceNotFoundException;

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

    @Inject
    IotShadowService shadowService;

    /**
     * Returns the current scheduling state of the device: the applied schedule and any
     * pending requested schedule. If the device has no schedule, all fields are null.
     *
     * @param deviceIn the logical device
     * @return the current scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO getSchedule(LogicalDevice deviceIn) {
        LogicalDevice device = logicalDeviceRepository.findWithSchedulesById(deviceIn.getId())
                .orElseThrow(() -> new DeviceAccessException("device not found"));
        return createScheduleStateDTO(device);
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
        device = logicalDeviceRepository.update(device);

        DeviceSchedule currentSchedule = deviceScheduleRepository
                .findByDeviceIdAndStatus(device.getId(), ScheduleStatus.APPLIED)
                .stream().findFirst().orElse(null);
        device.setCurrentSchedule(currentSchedule);

        // Attempt to update the shadow state of the device
        try {
            DeviceScheduleStateDTO dto = createScheduleStateDTO(device);
            shadowService.updateSchedule(device, dto.requestedSchedule());
            return dto;
        } catch (IOException ex) {
            throw new IllegalArgumentException("Invalid schedule");
        }
    }

    private BaseSchedule parseSchedule(String json) {
        try {
            return objectMapper.readValue(json, BaseSchedule.class);
        } catch (IOException e) {
            log.atSevere().withCause(e).log("Failed to parse schedule JSON: %s", json);
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

    public DeviceScheduleStateDTO createScheduleStateDTO(LogicalDevice device) {
        return new DeviceScheduleStateDTO(
                device.getCurrentSchedule() != null ? createScheduleDTO(device.getCurrentSchedule()) : null,
                device.getRequestedSchedule() != null ? createScheduleDTO(device.getRequestedSchedule()) : null,
                device.getRequestedSchedule() != null ? device.getRequestedSchedule().getStatus() : null
        );
    }

    public DeviceScheduleDTO createScheduleDTO(DeviceSchedule schedule) {
        return new DeviceScheduleDTO(schedule.getId(), schedule.getTakeEffect(),
                parseSchedule(schedule.getScheduleJson()));
    }
}
