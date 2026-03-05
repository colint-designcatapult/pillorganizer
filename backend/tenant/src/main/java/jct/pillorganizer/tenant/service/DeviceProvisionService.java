package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.DeviceClass;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.ProvisionRecordRepository;
import lombok.extern.flogger.Flogger;

import java.util.List;
import java.util.Optional;

@Singleton
@Flogger
public class DeviceProvisionService {

    @Inject
    ProvisionRecordRepository provisionRecordRepository;

    @Inject
    DeviceService deviceService;

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
                .orElseGet(() -> deviceService.create(user, deviceId));

        // Create provisioning record
        ProvisionRecord record = new ProvisionRecord();
        record.setClaimId(claimId);
        record.setLogicalDevice(logicalDevice);
        record.setSerialNo(serialNo);
        record.setThingName(thingName);
        record.setDeviceClass(DeviceClass.v1_7x2);
        record.setProvisionedBy(user);
        record.setThingName(thingName);
        return provisionRecordRepository.save(record);
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
        Optional<LogicalDevice> optionalDevice = deviceService.get(deviceId);

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
}
