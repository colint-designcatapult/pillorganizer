package jct.pillorganizer.tenant.service;

import jct.pillorganizer.tenant.dto.DeviceNotificationDetails;

public interface MobileNotificationService {

    void sendPillReminderNotification(DeviceNotificationDetails details);

}
