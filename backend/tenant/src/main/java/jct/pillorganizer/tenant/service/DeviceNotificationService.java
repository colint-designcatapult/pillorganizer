package jct.pillorganizer.tenant.service;

import io.micronaut.core.annotation.Nullable;
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
     * If the user is already subscribed the existing SNS subscription is kept
     * and only the preferences / filter policy are refreshed.
     *
     * <p>Null preference flags mean "keep whatever is currently stored" (or
     * default to {@code true} for a brand-new subscription).  Pass an explicit
     * {@code false} to disable a specific event type.</p>
     *
     * @param user            the user who wants notifications
     * @param device          the target device
     * @param endpointArn     the user's SNS platform-application endpoint ARN
     * @param notifyTakeNow   {@code false} to suppress TAKE_NOW notifications;
     *                        {@code null} preserves the stored preference
     * @param notifyTaken     {@code false} to suppress TAKEN notifications;
     *                        {@code null} preserves the stored preference
     * @param notifyMissed    {@code false} to suppress MISSED notifications;
     *                        {@code null} preserves the stored preference
     * @return updated {@link DeviceAccessDto} reflecting the new subscription state
     */
    @Transactional
    public DeviceAccessDto subscribe(User user, LogicalDevice device, String endpointArn,
                                     @Nullable Boolean notifyTakeNow,
                                     @Nullable Boolean notifyTaken,
                                     @Nullable Boolean notifyMissed) {
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

        // 3. Resolve effective preferences: null means "keep whatever is stored"
        //    (which itself defaults to true for rows that pre-date this feature).
        boolean effectiveTakeNow = notifyTakeNow != null ? notifyTakeNow : deviceUser.effectiveNotifyTakeNow();
        boolean effectiveTaken   = notifyTaken   != null ? notifyTaken   : deviceUser.effectiveNotifyTaken();
        boolean effectiveMissed  = notifyMissed  != null ? notifyMissed  : deviceUser.effectiveNotifyMissed();

        // 4. If already subscribed, sync preferences + filter policy and return.
        //    We must NOT skip this: a prior unsubscribe→re-subscribe cycle would
        //    have reset the SNS filter policy to "allow everything", so we always
        //    ensure the policy matches the stored preferences.
        if (deviceUser.getSubscriptionArn() != null) {
            log.atInfo().log("User %s already subscribed to device %s — syncing preferences", user.getId(), device.getId());
            savePreferencesAndFilterPolicy(deviceUser, effectiveTakeNow, effectiveTaken, effectiveMissed);
            return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
        }

        // 5. Create subscription
        String subscriptionArn = notificationService.subscribe(topicArn, endpointArn);
        deviceUserRepository.updateSubscriptionArn(deviceUser.getId(), subscriptionArn);
        deviceUser.setSubscriptionArn(subscriptionArn);

        // 6. Save notification preferences and set filter policy
        savePreferencesAndFilterPolicy(deviceUser, effectiveTakeNow, effectiveTaken, effectiveMissed);

        log.atInfo().log("Subscribed user %s to device %s topic", user.getId(), device.getId());
        return deviceMapper.toAccessDTO(deviceUser, tenantService.getCurrentTenant().orElse(null));
    }

    /** Backwards-compatible overload — preserves stored preferences (or defaults all to true for new subscriptions). */
    @Transactional
    public DeviceAccessDto subscribe(User user, LogicalDevice device, String endpointArn) {
        return subscribe(user, device, endpointArn, null, null, null);
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

        // Build the list of event types to BLOCK (inverted from the preference flags).
        // Passing this to setFilterPolicy produces an SNS "anything-but" policy that
        // suppresses exactly those event types.
        List<String> blocked = buildBlockedList(notifyTakeNow, notifyTaken, notifyMissed);
        notificationService.setFilterPolicy(deviceUser.getSubscriptionArn(), blocked);
    }

    /**
     * Builds the list of event type strings that should be <em>blocked</em> by the SNS
     * filter policy — i.e. the inverse of the "notify" preference flags.
     * A {@code false} flag means the user does not want that event type delivered,
     * so it is added to the blocked list.
     */
    static List<String> buildBlockedList(boolean notifyTakeNow, boolean notifyTaken, boolean notifyMissed) {
        List<String> blocked = new ArrayList<>();
        if (!notifyTakeNow) blocked.add("TAKE_NOW");
        if (!notifyTaken)   blocked.add("TAKEN");
        if (!notifyMissed)  blocked.add("MISSED");
        return blocked;
    }
}
