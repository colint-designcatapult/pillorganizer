package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.tenant.mapper.DeviceMapper;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import lombok.extern.flogger.Flogger;

/**
 * Orchestrates subscribing and unsubscribing a user to a device's SNS topic
 * for push-notification delivery.
 *
 * <ul>
 *   <li>On subscribe: ensures a topic exists for the device, then creates an
 *       SNS subscription linking the user's FCM endpoint ARN to that topic.
 *       The subscription ARN is persisted in {@code DeviceUser}.</li>
 *   <li>On unsubscribe: deletes the SNS subscription and clears the stored ARN.</li>
 * </ul>
 */
@Singleton
@Flogger
public class DeviceNotificationService {

    @Inject
    NotificationService notificationService;

    @Inject
    LogicalDeviceRepository logicalDeviceRepository;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceMapper deviceMapper;

    @Inject
    TenantService tenantService;

    /**
     * Subscribes {@code user} to push notifications for {@code device}.
     *
     * @param user        the user who wants notifications
     * @param device      the target device
     * @param endpointArn the user's SNS platform-application endpoint ARN
     * @return updated {@link DeviceAccessDto} reflecting the new subscription state
     */
    @Transactional
    public DeviceAccessDto subscribe(User user, LogicalDevice device, String endpointArn) {
        // 1. Ensure the device has a topic
        String topicArn = device.getTopicArn();
        if (topicArn == null) {
            topicArn = notificationService.createOrGetTopic(device.getId());
            logicalDeviceRepository.updateTopicArn(device.getId(), topicArn);
            device.setTopicArn(topicArn);
            log.atInfo().log("Created SNS topic for device %s", device.getId());
        }

        // 2. Fetch the DeviceUser row
        DeviceUser deviceUser = deviceUserRepository.findByUserAndDevice(user, device)
                .orElseThrow(() -> new IllegalStateException(
                        "User " + user.getId() + " has no access to device " + device.getId()));

        // 3. If already subscribed, return early (idempotent)
        if (deviceUser.getSubscriptionArn() != null) {
            log.atInfo().log("User %s already subscribed to device %s", user.getId(), device.getId());
            return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
        }

        // 4. Create subscription
        String subscriptionArn = notificationService.subscribe(topicArn, endpointArn);
        deviceUserRepository.updateSubscriptionArn(deviceUser.getId(), subscriptionArn);
        deviceUser.setSubscriptionArn(subscriptionArn);
        log.atInfo().log("Subscribed user %s to device %s topic", user.getId(), device.getId());

        return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
    }

    /**
     * Unsubscribes {@code user} from push notifications for {@code device}.
     *
     * @return updated {@link DeviceAccessDto} reflecting the cleared subscription state
     */
    @Transactional
    public DeviceAccessDto unsubscribe(User user, LogicalDevice device) {
        DeviceUser deviceUser = deviceUserRepository.findByUserAndDevice(user, device)
                .orElseThrow(() -> new IllegalStateException(
                        "User " + user.getId() + " has no access to device " + device.getId()));

        if (deviceUser.getSubscriptionArn() == null) {
            log.atInfo().log("User %s is not subscribed to device %s — nothing to do", user.getId(), device.getId());
            return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
        }

        notificationService.unsubscribe(deviceUser.getSubscriptionArn());
        deviceUserRepository.updateSubscriptionArn(deviceUser.getId(), null);
        deviceUser.setSubscriptionArn(null);
        log.atInfo().log("Unsubscribed user %s from device %s topic", user.getId(), device.getId());

        return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
    }
}
