package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.core.uid.UuidService;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.mapper.DeviceMapper;
import jct.pillorganizer.tenant.model.device.DeviceClass;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import jct.pillorganizer.tenant.repo.ProvisionRecordRepository;
import lombok.extern.flogger.Flogger;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Business logic for operations on Device objects.
 */
@Flogger
@Singleton
public class DeviceService {

    @Inject
    LogicalDeviceRepository logicalDeviceRepository;
    @Inject
    ProvisionRecordRepository provisionRecordRepository;
    @Inject
    UuidService uuidService;
    @Inject
    DeviceMapper deviceMapper;
    @Inject
    DeviceUserRepository deviceUserRepository;
    @Inject
    TenantService tenantService;
    @Inject
    private AuthService authService;

    @Transactional
    public ProvisionRecord provision(User user, String deviceId, String serialNo, String claimId, String thingName) {
        ClaimEligibility eligibility = this.getDeviceClaimEligibility(user, serialNo, deviceId);

        // Sanity check: user must still be eligible to provision the device
        // To prevent TOCTOU
        if(!eligibility.isEligible()) {
            log.atWarning().log("Attempting to provision device %s to user %s but they aren't eligible",
                    deviceId, user.getId());
            throw new DeviceAccessException("Not eligible to claim device");
        }

        // Use existing device, or create a new one
        LogicalDevice logicalDevice = eligibility.device
                .orElseGet(() -> this.create(user, deviceId));

        // Create provisioning record
        ProvisionRecord record = new ProvisionRecord();
        record.setClaimId(claimId);
        record.setLogicalDevice(logicalDevice);
        record.setSerialNo(serialNo);
        record.setThingName(thingName);
        record.setDeviceClass(DeviceClass.v1_7x2);
        record.setProvisionedBy(user);
        record.setThingName(thingName);
        record = provisionRecordRepository.save(record);
        assignActivePhysicalDevice(logicalDevice, record);
        return record;
    }

    public Optional<ProvisionRecord> findByClaimId(String claimId) {
        return provisionRecordRepository.findById(claimId);
    }

    public List<ProvisionRecord> getProvisionRecords(LogicalDevice logicalDevice) {
        return provisionRecordRepository.findAllByLogicalDevice(logicalDevice);
    }

    @Transactional
    public void assignActiveLogicalDevice(ProvisionRecord record, LogicalDevice device) {
        record.setDisabledAt(null);
        assignToLogicalDevice(record, device);
        provisionRecordRepository.disableAllForDeviceExcept(record);
        log.atInfo().log("Assigned provision record %s to logical device %s", record.getClaimId(),
                device.getId());
    }

    public void assignToLogicalDevice(ProvisionRecord record, LogicalDevice device) {
        record.setLogicalDevice(device);
        provisionRecordRepository.update(record);
    }

    public record ClaimEligibility(boolean isEligible, Optional<LogicalDevice> device) { }

    public ClaimEligibility getDeviceClaimEligibility(User user, String serialNo, String deviceId) {
        Optional<LogicalDevice> optionalDevice = this.get(deviceId);

        // If the logical device does not exist, they can provision it
        if(optionalDevice.isEmpty()) {
            return new ClaimEligibility(true, Optional.empty());
        }

        Optional<DeviceUser> deviceUser = optionalDevice.get().getUsers().stream()
                .filter(du -> du.getUser().getId().equals(user.getId()))
                .findFirst();

        // Check if this user is the primary user
        // Device can ONLY be provisioned to an existing device ID
        if(deviceUser.isPresent() && deviceUser.get().isPrimaryUser()) {
            return new ClaimEligibility(true, optionalDevice);
        }

        log.atInfo().log("User %s not primary user of %s, rejecting claim", user.getId(), deviceId);

        return new ClaimEligibility(false, optionalDevice);
    }

    @Transactional
    public LogicalDevice create(User user, String deviceId) {
        log.atInfo().log("Creating LogicalDevice for device %s user %s", deviceId, user.getId());

        // Create entity
        LogicalDevice device = new LogicalDevice();
        device.setId(deviceId);
        LogicalDevice persisted = logicalDeviceRepository.save(device);

        // Set primary user
        setPrimaryUser(persisted, user);

        return persisted;
    }

    @Transactional
    public LogicalDevice assignExisting(User user, ProvisionRecord record, String existingDeviceId) {
        if(record.getLogicalDevice() != null)
            throw new IllegalStateException("Device already assigned");

        LogicalDevice logicalDevice = this.get(existingDeviceId)
                .orElseThrow(() -> new DeviceAccessException("Device not found"));
        DeviceUser access = this.getUserAccess(user, logicalDevice)
                .orElseThrow(() -> new DeviceAccessException("User has no access to device"));
        if(!access.isPrimaryUser())
            throw new DeviceAccessException("User is not primary user of the device");
        return assignActivePhysicalDevice(logicalDevice, record);
    }

    @Transactional
    public LogicalDevice assignActivePhysicalDevice(LogicalDevice device, ProvisionRecord physicalDevice) {
        device.setPhysicalDevice(physicalDevice);
        logicalDeviceRepository.update(device);
        this.assignActiveLogicalDevice(physicalDevice, device);
        return device;
    }


    public List<DeviceAccessDto> getUserDevices(User user) {
        TenantDetails tenantDetails = tenantService.getCurrentTenant().orElse(null);
        return deviceUserRepository.findByUserId(user.getId())
                .stream()
                .map(du -> deviceMapper.toAccessDTO(du, tenantDetails))
                .collect(Collectors.toList());
    }

    public Optional<DeviceAccessDto> getUserDevice(User user, LogicalDevice device) {
        TenantDetails tenantDetails = tenantService.getCurrentTenant().orElse(null);
        return deviceUserRepository.findByUserAndDevice(user, device)
                .map(du -> deviceMapper.toAccessDTO(du, tenantDetails));
    }

    @Transactional
    public void addUserAccess(User user, LogicalDevice device) {
        Optional<DeviceUser> existing = deviceUserRepository.findByUserAndDevice(user, device);
        if (existing.isEmpty()) {
            DeviceUser du = new DeviceUser();
            du.setId(uuidService.generateUuid());
            du.setDevice(device);
            du.setUser(user);
            du.setPrimaryUser(false);
            deviceUserRepository.save(du);
        }
    }

    @Transactional
    public void setPrimaryUser(LogicalDevice device, User user) {
        List<DeviceUser> deviceUsers = deviceUserRepository.findByDeviceId(device.getId());
        for (DeviceUser du : deviceUsers) {
            boolean isTargetUser = du.getUser().getId().equals(user.getId());
            if (du.isPrimaryUser() != isTargetUser) {
                du.setPrimaryUser(isTargetUser);
                deviceUserRepository.update(du);
            }
        }
        // If the user wasn't already in the list, we should probably add them as primary
        if (deviceUsers.stream().noneMatch(du -> du.getUser().getId().equals(user.getId()))) {
            DeviceUser du = new DeviceUser();
            du.setId(uuidService.generateUuid());
            du.setUser(user);
            du.setDevice(device);
            du.setPrimaryUser(true);
            deviceUserRepository.save(du);
        }
        log.atInfo().log("Assigned %s primary user to %s", device.getId(), user.getId());
    }

    @Transactional
    public void removeUserAccess(User user, LogicalDevice device) {
        deviceUserRepository.delete(getUserAccess(user, device).get());
    }

    public Optional<DeviceUser> getUserAccess(User user, LogicalDevice device) {
        return deviceUserRepository.findByUserAndDevice(user, device);
    }

    public Optional<DeviceUser> getUserAccess(User user, String deviceId) {
        return deviceUserRepository.findByUserAndDeviceId(user, deviceId);
    }


    public Optional<LogicalDevice> get(String id) {
        return logicalDeviceRepository.findById(id);
    }

    public LogicalDevice updateNickname(LogicalDevice device, String nickname) {
        device.setNickname(nickname);
        logicalDeviceRepository.updateNickname(device.getId(), nickname);
        return device;
    }

}
