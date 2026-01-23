package jct.pillorganizer.device;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.WeekFields;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.micronaut.context.annotation.Requires;
import io.micronaut.scheduling.annotation.Scheduled;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceStateRepository;
import jct.pillorganizer.repo.DeviceUserRepository;
import jct.pillorganizer.service.DeviceStateService;
import jct.pillorganizer.service.MobileNotificationService;
import lombok.extern.flogger.Flogger;

/**
 * Transitions device bin state statuses when appropriate. For example, it will move a pill from "PENDING" to "TAKE NOW"
 * when appropriate. See backend documentation for details.
 */
@Singleton
@Flogger
@Requires(notEnv="test")
public class DeviceStateJob {

    @Inject
    DeviceStateRepository stateRepository;

    @Inject
    MobileNotificationService mobileNotificationService;

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceStateService deviceStateService;

    // Testing mode: Set to true to use 10-minute cycles instead of weekly cycles
    // This allows testing weekly reset logic without waiting 7 days
    private static final boolean TEST_MODE_SHORT_CYCLE = false;

    // Testing mode: Set to true to rebuild all schedules once per UTC day
    private static final boolean TEST_MODE_DAILY_RESET = true;

    // Duration of a cycle in seconds for testing mode (120 seconds = 2 minutes)
    private static final long TEST_CYCLE_DURATION_SECONDS = 120;

    // For test mode: track the cycle number based on elapsed time
    private Instant cycleStartTime = null;
    private int currentTestCycle = -1;

    private final Map<Long, WeekIdentifier> deviceWeekTracking = new HashMap<>();
    private final Map<Long, DayIdentifier> deviceDayTracking = new HashMap<>();

    @Scheduled(fixedDelay = "10s")
    public void execute() {
        Instant nowInstant = Instant.now();
        LocalDateTime nowUtc = LocalDateTime.ofInstant(nowInstant, ZoneOffset.UTC);

        if (TEST_MODE_SHORT_CYCLE) {
            // Test mode: Use configurable cycle duration instead of calendar weeks
            if (cycleStartTime == null) {
                // Initialize test cycle tracking
                cycleStartTime = nowInstant;
                currentTestCycle = 0;
                log.atInfo().log("TEST MODE: Initialized cycle tracking at time %s (cycle duration: %d seconds)", 
                        cycleStartTime.toString(), TEST_CYCLE_DURATION_SECONDS);
            }
            
            // Calculate which cycle we're in based on elapsed time
            long elapsed = nowInstant.getEpochSecond() - cycleStartTime.getEpochSecond();
            int testCycle = (int)(elapsed / TEST_CYCLE_DURATION_SECONDS);
            
            // Check if we've crossed into a new cycle
            if (testCycle != currentTestCycle) {
                log.atInfo().log("TEST MODE: New cycle detected (was cycle %d, now cycle %d). Triggering schedule rebuild for all devices...",
                        currentTestCycle, testCycle);
                currentTestCycle = testCycle;
                rebuildAllDeviceSchedules();
            }
        } else if (TEST_MODE_DAILY_RESET) {
            handleDailyReset(nowInstant);
        } else {
            evaluateDeviceWeekBoundaries(nowInstant);
        }

        // Normal state transitions
        stateRepository.updateBinStateFromTime(4, 3, nowUtc.toEpochSecond(ZoneOffset.UTC))
                .forEach(mobileNotificationService::sendPillReminderNotification);
        stateRepository.updateBinStateFromTime(2, 4, nowUtc.minusMinutes(10).toEpochSecond(ZoneOffset.UTC))
                .forEach(mobileNotificationService::sendPillReminderNotification);
    }

    /**
     * Rebuilds the schedule for all provisioned devices at the start of a new week.
     * This ensures that weekly medication schedules reset properly.
     */
    private void rebuildAllDeviceSchedules() {
        try {
            List<Device> devices = deviceRepository.findAllProvisioned();
            log.atInfo().log("Rebuilding schedules for %d provisioned devices", devices.size());
            for (Device device : devices) {
                rebuildScheduleForDevice(device);
            }
            log.atInfo().log("Completed weekly schedule rebuild for all devices");
        } catch (Exception e) {
            log.atSevere().withCause(e).log("Error during weekly schedule rebuild");
        }
    }

    private void rebuildScheduleForDevice(Device device) {
        try {
            // Get ALL non-deleted device users for this device
            // Each device user has their own state that needs to be reset
            List<DeviceUser> deviceUsers = deviceUserRepository.findByDeviceIDAndDeletedFalse(device.getId());

            if (deviceUsers.isEmpty()) {
                log.atWarning().log("No device users found for device %d (serial %d), skipping schedule rebuild",
                        device.getId(), device.getSerialNo());
                return;
            }

            // Rebuild schedule for each device user
            for (DeviceUser deviceUser : deviceUsers) {
                try {
                    DeviceStateWrapper wrapper = deviceStateService.wrapperOf(device, deviceUser);
                    wrapper.rebuildStateSchedule(true); // true = reset TAKEN bins for new week
                } catch (Exception e) {
                    log.atWarning().withCause(e).log("Failed to rebuild schedule for deviceUser %d of device %d",
                            deviceUser.getId(), device.getId());
                }
            }

            log.atInfo().log("Completed weekly reset for device %d (serial %d)",
                    device.getId(), device.getSerialNo());
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Failed to process device %d", device.getId());
        }
    }

    private void evaluateDeviceWeekBoundaries(Instant referenceInstant) {
        try {
            List<Device> devices = deviceRepository.findAllProvisioned();
            WeekFields weekFields = WeekFields.ISO;

            for (Device device : devices) {
                ZoneId zoneId = resolveZoneId(device);
                LocalDateTime deviceLocalTime = LocalDateTime.ofInstant(referenceInstant, zoneId);

                int weekOfYear = deviceLocalTime.get(weekFields.weekOfYear());
                int weekYear = deviceLocalTime.get(weekFields.weekBasedYear());

                WeekIdentifier trackedWeek = deviceWeekTracking.get(device.getId());
                if (trackedWeek == null) {
                    deviceWeekTracking.put(device.getId(), new WeekIdentifier(weekOfYear, weekYear));
                    log.atInfo().log("Initialized week tracking for device %d (serial %d) at week %d of %d in zone %s",
                            device.getId(), device.getSerialNo(), weekOfYear, weekYear, zoneId.getId());
                    continue;
                }

                if (trackedWeek.weekOfYear != weekOfYear || trackedWeek.weekYear != weekYear) {
                    log.atInfo().log("New week detected for device %d (serial %d) in zone %s: was week %d of %d, now week %d of %d. Triggering schedule rebuild...",
                            device.getId(), device.getSerialNo(), zoneId.getId(),
                            trackedWeek.weekOfYear, trackedWeek.weekYear, weekOfYear, weekYear);
                    rebuildScheduleForDevice(device);
                    deviceWeekTracking.put(device.getId(), new WeekIdentifier(weekOfYear, weekYear));
                }
            }
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Failed to evaluate weekly boundaries for devices");
        }
    }

    private void handleDailyReset(Instant referenceInstant) {
        try {
            List<Device> devices = deviceRepository.findAllProvisioned();

            for (Device device : devices) {
                ZoneId zoneId = resolveZoneId(device);
                LocalDateTime deviceLocalTime = LocalDateTime.ofInstant(referenceInstant, zoneId);
                int dayOfYear = deviceLocalTime.getDayOfYear();
                int year = deviceLocalTime.getYear();

                DayIdentifier trackedDay = deviceDayTracking.get(device.getId());
                if (trackedDay == null) {
                    deviceDayTracking.put(device.getId(), new DayIdentifier(dayOfYear, year));
                    log.atInfo().log("TEST MODE: Initialized daily reset tracking for device %d (serial %d) at day %d of %d in zone %s",
                            device.getId(), device.getSerialNo(), dayOfYear, year, zoneId.getId());
                    continue;
                }

                if (trackedDay.dayOfYear != dayOfYear || trackedDay.year != year) {
                    log.atInfo().log("TEST MODE: New day detected for device %d (serial %d) in zone %s: was day %d of %d, now day %d of %d. Rebuilding schedule...",
                            device.getId(), device.getSerialNo(), zoneId.getId(),
                            trackedDay.dayOfYear, trackedDay.year, dayOfYear, year);
                    rebuildScheduleForDevice(device);
                    deviceDayTracking.put(device.getId(), new DayIdentifier(dayOfYear, year));
                }
            }
        } catch (Exception e) {
            log.atWarning().withCause(e).log("TEST MODE: Failed to evaluate daily reset boundaries for devices");
        }
    }

    private ZoneId resolveZoneId(Device device) {
        String baseTz = device.getBaseTZ();
        if (baseTz == null || baseTz.isBlank()) {
            return ZoneOffset.UTC;
        }

        try {
            return ZoneId.of(baseTz.trim());
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Invalid timezone '%s' for device %d (serial %d). Falling back to UTC.",
                    baseTz, device.getId(), device.getSerialNo());
            return ZoneOffset.UTC;
        }
    }

    private static final class WeekIdentifier {
        private final int weekOfYear;
        private final int weekYear;

        private WeekIdentifier(int weekOfYear, int weekYear) {
            this.weekOfYear = weekOfYear;
            this.weekYear = weekYear;
        }
    }

    private static final class DayIdentifier {
        private final int dayOfYear;
        private final int year;

        private DayIdentifier(int dayOfYear, int year) {
            this.dayOfYear = dayOfYear;
            this.year = year;
        }
    }

}
