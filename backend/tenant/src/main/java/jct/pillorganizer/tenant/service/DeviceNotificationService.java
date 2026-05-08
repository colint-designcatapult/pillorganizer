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

import java.util.ArrayList;
import java.util.List;

/**
 * Orchestrates subscribing and unsubscribing a user to a device's SNS topic
 * for push-notification delivery, including per-user notification preferences
 * enforced via SNS filter policies.
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
     * @param user            the user who wants notifications
     * @param device          the target device
     * @param endpointArn     the user's SNS platform-application endpoint ARN
     * @param notifyTakeNow   whether to receive TAKE_NOW notifications
     * @param notifyTaken     whether to receive TAKEN notifications
     * @param notifyMissed    whether to receive MISSED notifications
     * @return updated {@link DeviceAccessDto} reflecting the new subscription state
     */
    @Transactional
    public DeviceAccessDto subscribe(User user, LogicalDevice device, String endpointArn,
                                     boolean notifyTakeNow, boolean notifyTaken, boolean notifyMissed) {
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

        // 5. Save notification preferences and set filter policy
        savePreferencesAndFilterPolicy(deviceUser, notifyTakeNow, notifyTaken, notifyMissed);

        log.atInfo().log("Subscribed user %s to device %s topic", user.getId(), device.getId());
        return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
    }

    /** Backwards-compatible overload — defaults all preferences to true. */
    @Transactional
    public DeviceAccessDto subscribe(User user, LogicalDevice device, String endpointArn) {
        return subscribe(user, device, endpointArn, true, true, true);
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

    /**
     * Updates notification preferences for an already-subscribed user.
     * Persists the preference flags and updates the SNS filter policy.
     *
     * @throws IllegalStateException if the user is not subscribed
     */
    @Transactional
    public DeviceAccessDto updatePreferences(User user, LogicalDevice device,
                                             boolean notifyTakeNow, boolean notifyTaken, boolean notifyMissed) {
        DeviceUser deviceUser = deviceUserRepository.findByUserAndDevice(user, device)
                .orElseThrow(() -> new IllegalStateException(
                        "User " + user.getId() + " has no access to device " + device.getId()));

        if (deviceUser.getSubscriptionArn() == null) {
            throw new IllegalStateException("User " + user.getId() + " is not subscribed to device " + device.getId());
        }

        savePreferencesAndFilterPolicy(deviceUser, notifyTakeNow, notifyTaken, notifyMissed);

        log.atInfo().log("Updated notification preferences for user %s on device %s", user.getId(), device.getId());
        return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
    }

    private void savePreferencesAndFilterPolicy(DeviceUser deviceUser,
                                                boolean notifyTakeNow, boolean notifyTaken, boolean notifyMissed) {
        deviceUserRepository.updateNotifyTakeNow(deviceUser.getId(), notifyTakeNow);
        deviceUserRepository.updateNotifyTaken(deviceUser.getId(), notifyTaken);
        deviceUserRepository.updateNotifyMissed(deviceUser.getId(), notifyMissed);
        deviceUser.setNotifyTakeNow(notifyTakeNow);
        deviceUser.setNotifyTaken(notifyTaken);
        deviceUser.setNotifyMissed(notifyMissed);

        List<String> excluded = buildExcludeList(notifyTakeNow, notifyTaken, notifyMissed);
        notificationService.setFilterPolicy(deviceUser.getSubscriptionArn(), excluded);
    }

    static List<String> buildExcludeList(boolean notifyTakeNow, boolean notifyTaken, boolean notifyMissed) {
        List<String> excluded = new ArrayList<>();
        if (!notifyTakeNow) excluded.add("TAKE_NOW");
        if (!notifyTaken)   excluded.add("TAKEN");
        if (!notifyMissed)  excluded.add("MISSED");
        return excluded;
    }
}
