package jct.pillorganizer.tenant.service;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.CaregiverListItemDTO;
import jct.pillorganizer.tenant.dto.DeviceCaregiverCodeDTO;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.CaregiverCode;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.CaregiverCodeRepository;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import lombok.extern.flogger.Flogger;

import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Business logic for caregiver invite codes, access management, and primary user transfer.
 */
@Flogger
@Singleton
public class CaregiverService {

    private static final int CODE_EXPIRY_MINUTES = 10;
    private static final SecureRandom RANDOM = new SecureRandom();

    @Inject
    CaregiverCodeRepository caregiverCodeRepository;

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Transactional
    public DeviceCaregiverCodeDTO generateCode(User patient, LogicalDevice device, String nickname) {
        // Invalidate any existing active codes for this device
        caregiverCodeRepository.invalidateAllForDevice(device.getId());

        int code = 100_000 + RANDOM.nextInt(900_000);
        Timestamp expiresAt = Timestamp.from(Instant.now().plus(CODE_EXPIRY_MINUTES, ChronoUnit.MINUTES));

        CaregiverCode entity = new CaregiverCode();
        entity.setId(UUID.randomUUID());
        entity.setDevice(device);
        entity.setPatient(patient);
        entity.setNickname(nickname);
        entity.setCode(code);
        entity.setExpiresAt(expiresAt);
        entity.setDeleted(false);
        entity = caregiverCodeRepository.save(entity);

        return new DeviceCaregiverCodeDTO(
                entity.getId(),
                patient.getId(),
                device.getId(),
                entity.getCode(),
                entity.getExpiresAt().getTime() / 1000,
                entity.isDeleted(),
                entity.getNickname()
        );
    }

    public List<DeviceCaregiverCodeDTO> getActiveCodesForDevices(List<String> deviceIds, User user) {
        Timestamp now = Timestamp.from(Instant.now());
        return deviceIds.stream()
                .flatMap(deviceId -> caregiverCodeRepository
                        .findByDeviceIdAndDeletedFalseAndExpiresAtGreaterThan(deviceId, now)
                        .stream())
                .filter(code -> code.getPatient().getId().equals(user.getId()))
                .map(code -> new DeviceCaregiverCodeDTO(
                        code.getId(),
                        code.getPatient().getId(),
                        code.getDevice().getId(),
                        code.getCode(),
                        code.getExpiresAt().getTime() / 1000,
                        code.isDeleted(),
                        code.getNickname()
                ))
                .collect(Collectors.toList());
    }

    @Transactional
    public CaregiverCodeValidationResult validateAndJoin(int code, User caregiver) {
        Timestamp now = Timestamp.from(Instant.now());
        CaregiverCode caregiverCode = caregiverCodeRepository
                .findByCodeAndDeletedFalseAndExpiresAtGreaterThan(code, now)
                .orElseThrow(() -> new DeviceAccessException("Invalid or expired code"));

        LogicalDevice device = caregiverCode.getDevice();

        // Don't allow primary user to join as caregiver on their own device
        Optional<DeviceUser> existingAccess = deviceService.getUserAccess(caregiver, device);
        if (existingAccess.isPresent()) {
            throw new DeviceAccessException("You already have access to this device");
        }

        deviceService.addUserAccess(caregiver, device);

        // Copy the nickname from the invite code to the new DeviceUser record
        DeviceUser newAccess = deviceUserRepository.findByUserAndDevice(caregiver, device)
                .orElseThrow(() -> new IllegalStateException("DeviceUser not found after creation"));
        deviceUserRepository.updateNickname(newAccess.getId(), caregiverCode.getNickname());

        caregiverCodeRepository.markDeleted(caregiverCode.getId());

        String deviceName = device.getNickname() != null ? device.getNickname() : "Device #" + device.getId();
        log.atInfo().log("Caregiver %s joined device %s via invite code", caregiver.getId(), device.getId());
        return new CaregiverCodeValidationResult(deviceName);
    }

    @Serdeable
    public record CaregiverCodeValidationResult(String name) {}

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

    public List<CaregiverListItemDTO> listCaregivers(String deviceId, User requester) {
        // Verify requester has access to this device
        deviceUserRepository.findByUserAndDeviceId(requester, deviceId)
                .orElseThrow(() -> new DeviceAccessException("No access to device"));

        return deviceUserRepository.findByDeviceId(deviceId).stream()
                .map(du -> {
                    String userName = du.getUser().getName();
                    if (userName == null) userName = du.getUser().getEmail();
                    if (userName == null) userName = du.getUser().getId();
                    return new CaregiverListItemDTO(
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
