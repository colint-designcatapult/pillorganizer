package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.repo.DeviceRepo;

@Singleton
public class DeviceService {

    @Inject
    DeviceRepo deviceRepo;

    @Value("${app.tenant.default}")
    String defaultTenant;

    public String lookupTenant(String serialNumber) {
        return deviceRepo.findBySerialNumber(serialNumber)
                .map(DeviceEntity::getTenantId)
                .orElse(defaultTenant);
    }
}
