package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.repo.DeviceTenantMappingRepo;

import java.util.Optional;

@Singleton
public class DeviceService {

    @Inject
    DeviceTenantMappingRepo deviceTenantMappingRepo;

    @Inject
    DeviceRepo deviceRepo;

    @Value("${app.tenant.default}")
    String defaultTenant;

    // @relation(CTRL-REQ-16, scope=range_start)
    public String lookupTenant(String serialNumber) {
        return deviceTenantMappingRepo.findBySerialNumber(serialNumber)
                .map(DeviceTenantMappingEntity::getTenantId)
                .orElse(defaultTenant);
    }
    // @relation(CTRL-REQ-16, scope=range_end)

    public Optional<DeviceEntity> getDevice(String deviceId) {
        return deviceRepo.findByDeviceId(deviceId);
    }
}
