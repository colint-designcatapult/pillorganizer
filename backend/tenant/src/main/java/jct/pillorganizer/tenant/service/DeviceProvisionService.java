package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.model.device.DeviceClass;
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

    public ProvisionRecord provision(User user, String deviceID, String serialNo, String claimToken) {
        // Create provisioning record
        ProvisionRecord record = new ProvisionRecord();
        record.setDeviceId(deviceID);
        record.setSerialNo(serialNo);
        record.setClaimToken(claimToken);
        record.setDeviceClass(DeviceClass.v1_7x2);
        record.setProvisionedBy(user);
        return provisionRecordRepository.save(record);
    }

    public Optional<ProvisionRecord> findById(String id) {
        return provisionRecordRepository.findById(id);
    }

    public Optional<ProvisionRecord> findByClaimToken(User user, String claimToken) {
        return provisionRecordRepository.findByProvisionedByAndClaimToken(user, claimToken);
    }

    public List<ProvisionRecord> findUnassignedProvisionRecord(User user) {
        return provisionRecordRepository.findByProvisionedByAndLogicalDeviceIsNull(user);
    }

    public List<ProvisionRecord> getProvisionRecords(LogicalDevice logicalDevice) {
        return provisionRecordRepository.findAllByLogicalDevice(logicalDevice);
    }

    @Transactional
    public void assignActiveLogicalDevice(ProvisionRecord record, LogicalDevice device) {
        record.setDisabledAt(null);
        assignToLogicalDevice(record, device);
        provisionRecordRepository.disableAllForDeviceExcept(record);
        log.atInfo().log("Assigned provision record %s to logical device %s", record.getDeviceId(),
                device.getId());
    }

    public void assignToLogicalDevice(ProvisionRecord record, LogicalDevice device) {
        record.setLogicalDevice(device);
        provisionRecordRepository.update(record);
    }

}
