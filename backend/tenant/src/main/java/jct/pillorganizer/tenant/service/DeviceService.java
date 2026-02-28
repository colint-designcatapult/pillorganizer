package jct.pillorganizer.tenant.service;

import jakarta.transaction.Transactional;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.repo.DeviceRepository;

/**
 * Business logic for operations on Device objects.
 */
@Singleton
public class DeviceService {

    @Inject
    DeviceRepository deviceRepository;

    @Transactional
    public Device create(String deviceId, String serialNo, String claimToken) {
        Device device = new Device();
        device.setId(deviceId);
        device.setSerialNo(serialNo);
        device.setClaimToken(claimToken);
        return deviceRepository.save(device);
    }

    @Transactional
    public Device findById(String id) {
        return deviceRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Device not found"));
    }
}
