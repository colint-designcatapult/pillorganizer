package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.message.IotDeviceEventMessage;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import lombok.extern.flogger.Flogger;

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
     * (QoS-1 "at least once" re-deliveries) via {@code ON CONFLICT DO NOTHING}. All other errors
     * propagate to the caller so the SQS message is routed to the dead-letter queue.
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

        deviceEventRepository.saveIdempotent(
                event.getId(),
                event.getLogicalDevice().getId(),
                event.getTimestamp(),
                event.getEventType(),
                event.getBinId(),
                event.getMetadata(),
                event.getScheduleId()
        );
        log.atInfo().log("Processed device event for thing %s (type=%s)",
                message.thingName(), event.getEventType());
    }
}
