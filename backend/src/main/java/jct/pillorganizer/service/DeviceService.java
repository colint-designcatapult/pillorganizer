package jct.pillorganizer.service;

import javax.transaction.Transactional;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceClass;
import jct.pillorganizer.repo.DeviceRepository;

/**
 * Business logic for operations on Device objects.
 */
@Singleton
public class DeviceService {


    @Inject
    DeviceRepository deviceRepository;

    /**
     * Fetches a Device object by serial number and class, if such device already exists, and if not, creates a new
     * Device object with those specifications.
     * @param sn serial number of the device
     * @param deviceClass class of the device
     * @return Device domain object, either existing or freshly persisted into the database
     */
    @Transactional
    public Device findOrCreateDevice(long sn, DeviceClass deviceClass) {
        return deviceRepository.findBySerialNo(sn).orElseGet(() -> {
            Device d = new Device();
            d.setId(null);
            d.setSerialNo(sn);
            d.setDeviceClass(deviceClass);
            return deviceRepository.save(d);
        });
    }

    @Transactional
    public Device findById(long id) {
        return deviceRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Device not found"));
    }
}
