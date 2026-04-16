package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.message.IotDeviceEventMessage;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import lombok.extern.flogger.Flogger;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Flogger
@Singleton
public class DeviceEventService {

    static final String EVENT_TAKEN = "TAKEN";
    static final String EVENT_TAKE_NOW = "TAKE_NOW";
    static final String EVENT_MISSED = "MISSED";
    static final long NOTIFICATION_TTL_SECONDS = 15 * 60L; // 15 minutes

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceEventRepository deviceEventRepository;

    @Inject
    NotificationService notificationService;

    /**
     * Processes an incoming IoT device event message.
     * <p>
     * Looks up the {@link LogicalDevice} for the provided {@code thingName}, constructs the
     * {@link DeviceEvent} entity, and persists it. A unique constraint on
     * {@code (logical_device_id, timestamp, event_type, bin_id)} silently drops duplicate messages
     * (QoS-1 "at least once" re-deliveries) via {@code ON CONFLICT DO NOTHING}. All other errors
     * propagate to the caller so the SQS message is routed to the dead-letter queue.
     * </p>
     * <p>
     * For {@code TAKEN} and {@code MISSED} events a push notification is published to the
     * device's SNS topic so all subscribed users are notified.
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

        maybeNotify(logicalDevice, message.eventType(), message.binId(), Instant.ofEpochMilli(message.timestamp()));
    }

    private String decodeBin(int binId) {
        return switch(binId) {
            case 0 -> "Monday PM";
            case 1 -> "Monday AM";
            case 2 -> "Tuesday PM";
            case 3 -> "Tuesday AM";
            case 4 -> "Wednesday PM";
            case 5 -> "Wednesday AM";
            case 6 -> "Thursday PM";
            case 7 -> "Thursday AM";
            case 8 -> "Friday PM";
            case 9 -> "Friday AM";
            case 10 -> "Saturday PM";
            case 11 -> "Saturday AM";
            case 12 -> "Sunday PM";
            case 13 -> "Sunday AM";
            default -> ""; // for all other cases, fall back to nothing (failsafe)
        };
    }

    private void maybeNotify(LogicalDevice device, String eventType, Integer binId, Instant eventTimestamp) {
        if (device.getTopicArn() == null) {
            return;
        }

        long ttlSeconds = NOTIFICATION_TTL_SECONDS - Duration.between(eventTimestamp, Instant.now()).getSeconds();
        if (ttlSeconds <= 0) {
            log.atInfo().log("Skipping notification for device %s (event=%s) — TTL expired (%ds over limit)",
                    device.getId(), eventType, -ttlSeconds);
            return;
        }

        String notificationMessage;
        switch (eventType) {
            case EVENT_TAKE_NOW -> notificationMessage = "Time for your scheduled " + decodeBin(binId) + " dose.";
            case EVENT_TAKEN -> notificationMessage = "Your " + decodeBin(binId) + " dose was recorded as taken.";
            case EVENT_MISSED -> notificationMessage = "Reminder: no activity detected for the " + decodeBin(binId) + " dose.";
            case null, default -> {
                return;
            }
        }

        try {
            notificationService.publish(device.getTopicArn(), "CabiNET: " + device.getNickname(), notificationMessage, ttlSeconds);
            log.atInfo().log("Published %s notification for device %s (ttl=%ds)", eventType, device.getId(), ttlSeconds);
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Failed to publish notification for device %s (event=%s)",
                    device.getId(), eventType);
            throw e;
        }
    }
}

