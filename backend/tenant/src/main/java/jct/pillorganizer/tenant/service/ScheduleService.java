package jct.pillorganizer.tenant.service;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.ObjectMapper;

import java.io.IOException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.ShadowStateDto;
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

    public DeviceSchedule get(UUID id) {
        return deviceScheduleRepository.findById(id)
                .orElseThrow(() -> new DeviceAccessException("schedule not found"));
    }

    /**
     * Returns the current scheduling state of the device: the applied schedule and any
     * pending requested schedule. If the device has no schedule, all fields are null.
     *
     * @param deviceIn the logical device
     * @return the current scheduling state
     */
    @Transactional
    public DeviceScheduleStateDTO getSchedule(LogicalDevice deviceIn) {
        LogicalDevice device = logicalDeviceRepository.getById(deviceIn.getId())
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
            throw new IllegalArgumentException("Invalid schedule", ex);
        }
    }

    @Transactional
    public void processScheduleDocument(String thingName, ShadowStateDto<DeviceScheduleDTO> shadowStateDto) {
        log.atInfo().log("Processing schedule update for %s (version %s)", thingName, shadowStateDto.toString());

        DeviceScheduleDTO reported = shadowStateDto.state().reported();

        if(reported != null) {
            if(reported.id() == null) {
                log.atWarning().log("Thing %s reported schedule with no ID", thingName);
                return;
            }
            DeviceSchedule scheduleEntity = deviceScheduleRepository.findById(reported.id())
                    .orElseThrow(() -> new IllegalStateException("Reported schedule does not exist"));

            if(thingName == null) {
                throw new IllegalArgumentException("No thing name provided");
            }

            if(scheduleEntity.getDevice() == null) {
                throw new IllegalStateException("Reported schedule has no device for ID " + scheduleEntity.getId());
            }

            if(scheduleEntity.getDevice().getPhysicalDevice() == null) {
                throw new IllegalStateException("Reported schedule has no physical device for ID " + scheduleEntity.getId());
            }

            if(!scheduleEntity.getDevice().getPhysicalDevice().getThingName().equals(thingName)) {
                log.atWarning().log("Schedule entity device thing name did not match provided (%s != %s)",
                        scheduleEntity.getDevice().getPhysicalDevice().getThingName(), thingName);
                throw new DeviceAccessException("Attempted to update schedule for thing " + thingName);
            }

            if(scheduleEntity.getStatus() == ScheduleStatus.PENDING) {
                // If the schedule is currently marked as pending the DB, we can conclude the schedule has been
                // applied by the device. Update DB entities appropriately.
                setActiveSchedule(scheduleEntity.getDevice(), scheduleEntity);
            }
        } else {
            log.atWarning().log("Schedule doc has no reported or desired state");
        }
    }

    @Transactional
    public void setActiveSchedule(LogicalDevice device, DeviceSchedule schedule) {
        log.atInfo().log("Updating %s schedule to %s", device.getId(), schedule.getId());
        DeviceSchedule currentSchedule = device.getCurrentSchedule();
        DeviceSchedule requestedSchedule = device.getRequestedSchedule();
        if(currentSchedule != null && !currentSchedule.getId().equals(schedule.getId())) {
            // Current schedule is now obsolete, mark it as superseded
            currentSchedule.setStatus(ScheduleStatus.SUPERSEDED);
            deviceScheduleRepository.update(currentSchedule);
        }

        if(requestedSchedule != null && !requestedSchedule.getId().equals(schedule.getId())) {
            // If another request is pending, supersede it
            requestedSchedule.setStatus(ScheduleStatus.SUPERSEDED);
            deviceScheduleRepository.update(currentSchedule);
        }


        // Set new schedule as applied
        schedule.setStatus(ScheduleStatus.APPLIED);
        deviceScheduleRepository.update(schedule);

        // Update device's current schedule pointer
        device.setCurrentSchedule(schedule);
        logicalDeviceRepository.updateCurrentSchedule(device, schedule);

        // Clear requested schedule entry, it's obsolete
        device.setRequestedSchedule(null);
        logicalDeviceRepository.updateRequestedSchedule(device, null);
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
