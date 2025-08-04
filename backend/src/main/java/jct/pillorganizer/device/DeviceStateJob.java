package jct.pillorganizer.device;

import io.micronaut.context.annotation.Requires;
import io.micronaut.scheduling.annotation.Scheduled;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.repo.DeviceStateRepository;
import jct.pillorganizer.service.FirebaseMessageService;
import lombok.extern.flogger.Flogger;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

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

    @Scheduled(fixedDelay = "10s")
    public void execute() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);

        stateRepository.updateBinStateFromTime(4, 3, now.toEpochSecond(ZoneOffset.UTC))
                .forEach(messageService::sendPillReminderNotification);
        stateRepository.updateBinStateFromTime(2, 4, now.minusMinutes(10).toEpochSecond(ZoneOffset.UTC))
                .forEach(messageService::sendPillReminderNotification);
    }

}
