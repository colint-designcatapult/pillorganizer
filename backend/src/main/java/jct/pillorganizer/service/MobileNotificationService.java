package jct.pillorganizer.service;

import jakarta.inject.Singleton;
import jct.pillorganizer.dto.DeviceNotificationDetails;

public interface MobileNotificationService {

    void sendPillReminderNotification(DeviceNotificationDetails details);

}
