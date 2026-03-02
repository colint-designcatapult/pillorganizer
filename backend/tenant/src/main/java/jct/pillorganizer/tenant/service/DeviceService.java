package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.core.uid.UuidService;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.mapper.DeviceMapper;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository;
import lombok.extern.flogger.Flogger;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
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
    DeviceProvisionService deviceProvisionService;
    @Inject
    UuidService uuidService;
    @Inject
    DeviceMapper deviceMapper;
    @Inject
    DeviceUserRepository deviceUserRepository;
    @Inject
    TenantService tenantService;

    @Transactional
    public LogicalDevice create(User user, ProvisionRecord physicalDevice) {
        if(physicalDevice.getLogicalDevice() != null)
            throw new IllegalStateException("Device already assigned");

        log.atInfo().log("Creating LogicalDevice for device %s, user %s", physicalDevice.getDeviceId(), user.getId());
        if(!user.getId().equals(physicalDevice.getProvisionedBy().getId())) {
            log.atWarning().log("Attempted to create a device for user %s for device provisioned by %s",
                    user.getId(), physicalDevice.getProvisionedBy().getId());
            throw new DeviceAccessException("Provision record doesn't match user");
        }

        LogicalDevice device = new LogicalDevice();
        device.setId(uuidService.generateUuid());
        device.setPhysicalDevice(physicalDevice);
        LogicalDevice persisted = logicalDeviceRepository.save(device);
        deviceProvisionService.assignActiveLogicalDevice(physicalDevice, persisted);

        setPrimaryUser(persisted, physicalDevice.getProvisionedBy());
        return persisted;
    }

    @Transactional
    public LogicalDevice assignExisting(User user, ProvisionRecord record, String existingDeviceId) {
        if(record.getLogicalDevice() != null)
            throw new IllegalStateException("Device already assigned");

        LogicalDevice logicalDevice = this.get(UUID.fromString(existingDeviceId))
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
        deviceProvisionService.assignActiveLogicalDevice(physicalDevice, device);
        return device;
    }

    public List<DeviceAccessDto> getUserDevices(User user) {
        TenantDetails tenantDetails = tenantService.getCurrentTenant().orElse(null);
        return deviceUserRepository.findByUserId(user.getId())
                .stream()
                .map(du -> deviceMapper.toAccessDTO(du, tenantDetails))
                .collect(Collectors.toList());
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

    public Optional<LogicalDevice> get(UUID id) {
        return logicalDeviceRepository.findById(id);
    }

}
