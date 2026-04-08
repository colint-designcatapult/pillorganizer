package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.message.IotDeviceEventMessage;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import lombok.extern.flogger.Flogger;

import java.sql.SQLException;
import java.time.Instant;
import java.util.UUID;

@Flogger
@Singleton
public class DeviceEventService {

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceEventRepository deviceEventRepository;

    /**
     * Processes an incoming IoT device event message.
     * <p>
     * Looks up the {@link LogicalDevice} for the provided {@code thingName}, constructs the
     * {@link DeviceEvent} entity, and persists it. A unique constraint on
     * {@code (logical_device_id, timestamp, event_type, bin_id)} silently drops duplicate messages
     * (QoS-1 "at least once" re-deliveries). All other errors propagate to the caller so the SQS
     * message is routed to the dead-letter queue.
     * </p>
     *
     * @param message the incoming device event message
     * @throws IllegalStateException if no {@link LogicalDevice} is found for the given thingName
     */
    public void processEvent(IotDeviceEventMessage message) {
        log.atInfo().log("Processing device event: thingName=%s, tenant=%s, timestamp=%d, eventType=%s, binId=%s, flags=%s, scheduleId=%s",
                message.thingName(), message.tenant(), message.timestamp(), message.eventType(),
                message.binId(), message.flags(), message.scheduleId());

        LogicalDevice logicalDevice = deviceService.findByThingName(message.thingName())
                .orElseThrow(() -> new IllegalStateException(
                        "No logical device found for thingName: " + message.thingName()));

        String metadata = message.flags() != null
                ? "{\"flags\":" + message.flags() + "}"
                : null;

        DeviceEvent event = new DeviceEvent();
        event.setId(UUID.randomUUID());
        event.setLogicalDevice(logicalDevice);
        event.setTimestamp(Instant.ofEpochMilli(message.timestamp()));
        event.setEventType(message.eventType());
        event.setBinId(message.binId());
        event.setMetadata(metadata);
        event.setScheduleId(message.scheduleId());

        try {
            deviceEventRepository.save(event);
            log.atInfo().log("Saved device event %s for thing %s (type=%s)",
                    event.getId(), message.thingName(), event.getEventType());
        } catch (Exception e) {
            if (isDuplicateKeyException(e)) {
                log.atInfo().log("Duplicate device event dropped for thing %s (timestamp=%d, type=%s, binId=%s)",
                        message.thingName(), message.timestamp(), message.eventType(), message.binId());
            } else {
                throw e;
            }
        }
    }

    private boolean isDuplicateKeyException(Throwable e) {
        Throwable cause = e;
        while (cause != null) {
            if (cause instanceof SQLException sqlException) {
                // '23505' is the standard PostgreSQL SQLState for unique_violation
                return "23505".equals(sqlException.getSQLState());
            }
            cause = cause.getCause();
        }
        return false;
    }
}
