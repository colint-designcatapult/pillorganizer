package jct.pillorganizer.tenant.service.fake;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.DeviceNotificationDetails;
import jct.pillorganizer.tenant.service.MobileNotificationService;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class FakeNotificationService implements MobileNotificationService {
    @Override
    public void sendPillReminderNotification(DeviceNotificationDetails details) {
        log.atInfo().log("Mock mobile notification to token %s device %s[%d]",
                details.notificationToken(), details.deviceName(), details.deviceID());
    }
}
