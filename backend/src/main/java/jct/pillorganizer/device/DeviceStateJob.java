package jct.pillorganizer.device;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.temporal.WeekFields;
import java.util.List;

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
import jct.pillorganizer.service.FirebaseMessageService;
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
    FirebaseMessageService messageService;

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceStateService deviceStateService;

    // Testing mode: Set to true to use 10-minute cycles instead of weekly cycles
    // This allows testing weekly reset logic without waiting 7 days
    private static final boolean TEST_MODE_SHORT_CYCLE = false;
    
    // Duration of a cycle in seconds for testing mode (120 seconds = 2 minutes)
    private static final long TEST_CYCLE_DURATION_SECONDS = 120;

    // Track the current week to detect week boundaries
    private int currentWeekOfYear = -1;
    private int currentYear = -1;
    
    // For test mode: track the cycle number based on elapsed time
    private Instant cycleStartTime = null;
    private int currentTestCycle = -1;

    @Scheduled(fixedDelay = "10s")
    public void execute() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);

        if (TEST_MODE_SHORT_CYCLE) {
            // Test mode: Use configurable cycle duration instead of calendar weeks
            Instant nowInstant = Instant.now();
            
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
        } else {
            // Production mode: Use ISO calendar weeks (Monday = start of week)
            // This ensures the reset triggers at midnight between Sunday and Monday
            WeekFields weekFields = WeekFields.ISO;
            int weekOfYear = now.get(weekFields.weekOfYear());
            int year = now.getYear();

            // Detect new week boundary
            if ((currentWeekOfYear != -1 && currentWeekOfYear != weekOfYear) || 
                (currentYear != -1 && currentYear != year)) {
                log.atInfo().log("New week detected (was week %d of %d, now week %d of %d). Triggering weekly schedule rebuild for all devices...",
                        currentWeekOfYear, currentYear, weekOfYear, year);
                
                // Rebuild schedule for all provisioned devices
                rebuildAllDeviceSchedules();
                
                currentWeekOfYear = weekOfYear;
                currentYear = year;
            } else if (currentWeekOfYear == -1) {
                // First run, just initialize
                currentWeekOfYear = weekOfYear;
                currentYear = year;
                log.atInfo().log("Initialized week tracking: week %d of year %d", weekOfYear, year);
            }
        }

        // Normal state transitions
        stateRepository.updateBinStateFromTime(4, 3, now.toEpochSecond(ZoneOffset.UTC))
                .forEach(messageService::sendPillReminderNotification);
        stateRepository.updateBinStateFromTime(2, 4, now.minusMinutes(10).toEpochSecond(ZoneOffset.UTC))
                .forEach(messageService::sendPillReminderNotification);
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
                try {
                    // Get ALL non-deleted device users for this device
                    // Each device user has their own state that needs to be reset
                    List<DeviceUser> deviceUsers = deviceUserRepository.findByDeviceIDAndDeletedFalse(device.getId());
                    
                    if (deviceUsers.isEmpty()) {
                        log.atWarning().log("No device users found for device %d (serial %d), skipping schedule rebuild",
                                device.getId(), device.getSerialNo());
                        continue;
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
            
            log.atInfo().log("Completed weekly schedule rebuild for all devices");
        } catch (Exception e) {
            log.atSevere().withCause(e).log("Error during weekly schedule rebuild");
        }
    }

}
