package jct.pillorganizer.tenant.service;

import io.micronaut.core.annotation.Nullable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.CaregiverListItemDto;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import lombok.extern.flogger.Flogger;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Business logic for caregiver access management and primary user transfer.
 */
@Flogger
@Singleton
public class CaregiverService {

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    UserService userService;

    /**
     * Invites a caregiver to a device by ensuring the user record exists in the tenant
     * and granting device access with the given nickname.
     *
     * @param requester         the authenticated user making the request (must be primary user)
     * @param device            the logical device to grant access to
     * @param caregiverUserId   the user ID of the caregiver (from control plane)
     * @param caregiverEmail    the email of the caregiver
     * @param caregiverUserName the display name of the caregiver (may be null)
     * @param nickname          the nickname for this caregiver on the device
     */
    @Transactional
    public CaregiverListItemDto inviteCaregiver(User requester, LogicalDevice device, String caregiverUserId,
                                String caregiverEmail, @Nullable String caregiverUserName,
                                String nickname) {
        // Verify requester is primary user
        DeviceUser requesterAccess = deviceUserRepository.findByUserAndDevice(requester, device)
                .orElseThrow(() -> new DeviceAccessException("No access to device"));
        if (!requesterAccess.isPrimaryUser()) {
            throw new DeviceAccessException("Only the primary user can invite caregivers");
        }

        // Ensure the caregiver user record exists in the tenant
        User caregiver = userService.upsert(caregiverUserId, caregiverUserName, caregiverEmail);

        // Check if caregiver already has access
        Optional<DeviceUser> existingAccess = deviceService.getUserAccess(caregiver, device);
        if (existingAccess.isPresent()) {
            throw new DeviceAccessException("User already has access to this device");
        }

        // Grant access
        deviceService.addUserAccess(caregiver, device);

        // Set nickname
        DeviceUser newAccess = deviceUserRepository.findByUserAndDevice(caregiver, device)
                .orElseThrow(() -> new IllegalStateException("DeviceUser not found after creation"));
        deviceUserRepository.updateNickname(newAccess.getId(), nickname);

        log.atInfo().log("Caregiver %s invited to device %s by primary user %s",
                caregiverUserId, device.getId(), requester.getId());

        String userName = caregiver.getName();
        if (userName == null) userName = caregiver.getEmail();
        if (userName == null) userName = caregiver.getId();
        return new CaregiverListItemDto(newAccess.getId(), userName, nickname, false);
    }

    @Transactional
    public void revokeCaregiver(UUID deviceUserId, User requester) {
        DeviceUser targetUser = deviceUserRepository.findById(deviceUserId)
                .orElseThrow(() -> new DeviceAccessException("Caregiver not found"));

        // Verify requester is primary user of the same device
        DeviceUser requesterAccess = deviceUserRepository.findByUserAndDevice(requester, targetUser.getDevice())
                .orElseThrow(() -> new DeviceAccessException("No access to device"));
        if (!requesterAccess.isPrimaryUser()) {
            throw new DeviceAccessException("Only the primary user can revoke caregiver access");
        }

        if (targetUser.isPrimaryUser()) {
            throw new DeviceAccessException("Cannot revoke the primary user");
        }

        deviceUserRepository.delete(targetUser);
        log.atInfo().log("Primary user %s revoked caregiver %s from device %s",
                requester.getId(), targetUser.getUser().getId(), targetUser.getDevice().getId());
    }

    public List<CaregiverListItemDto> listCaregivers(String deviceId, User requester) {
        // Verify requester has access to this device
        deviceUserRepository.findByUserAndDeviceId(requester, deviceId)
                .orElseThrow(() -> new DeviceAccessException("No access to device"));

        return deviceUserRepository.findByDeviceId(deviceId).stream()
                .map(du -> {
                    String userName = du.getUser().getName();
                    if (userName == null) userName = du.getUser().getEmail();
                    if (userName == null) userName = du.getUser().getId();
                    return new CaregiverListItemDto(
                            du.getId(),
                            userName,
                            du.getNickname(),
                            du.isPrimaryUser()
                    );
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public void transferPrimaryUser(String deviceId, UUID targetDeviceUserId, User currentPrimary) {
        DeviceUser currentAccess = deviceUserRepository.findByUserAndDeviceId(currentPrimary, deviceId)
                .orElseThrow(() -> new DeviceAccessException("No access to device"));
        if (!currentAccess.isPrimaryUser()) {
            throw new DeviceAccessException("Only the current primary user can transfer primary status");
        }

        DeviceUser target = deviceUserRepository.findById(targetDeviceUserId)
                .orElseThrow(() -> new DeviceAccessException("Target user not found"));

        if (!target.getDevice().getId().equals(deviceId)) {
            throw new DeviceAccessException("Target user does not belong to this device");
        }

        LogicalDevice device = currentAccess.getDevice();
        deviceService.setPrimaryUser(device, target.getUser());
        log.atInfo().log("Primary user transferred from %s to %s on device %s",
                currentPrimary.getId(), target.getUser().getId(), deviceId);
    }
}
