package jct.pillorganizer.service.fake;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.dto.DeviceNotificationDetails;
import jct.pillorganizer.service.MobileNotificationService;
import lombok.extern.flogger.Flogger;

@Requires(notEnv = "prod")
@Singleton
@Flogger
public class FakeNotificationService implements MobileNotificationService {
    @Override
    public void sendPillReminderNotification(DeviceNotificationDetails details) {
        log.atInfo().log("Mock mobile notification to token %s device %s[%d]",
                details.notificationToken(), details.deviceName(), details.deviceID());
    }
}
