package jct.pillorganizer.global.domain.repo;

import jct.pillorganizer.global.domain.model.Device;

import java.util.Optional;

public interface DeviceRepo {
    Optional<Device> get(String deviceId);
    Optional<Device> findBySerialNumber(String serialNumber);
}
