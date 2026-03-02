package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;
import jct.pillorganizer.global.repo.DeviceTenantMappingRepo;

@Singleton
public class DeviceService {

    @Inject
    DeviceTenantMappingRepo deviceTenantMappingRepo;

    @Value("${app.tenant.default}")
    String defaultTenant;

    public String lookupTenant(String serialNumber) {
        return deviceTenantMappingRepo.findBySerialNumber(serialNumber)
                .map(DeviceTenantMappingEntity::getTenantId)
                .orElse(defaultTenant);
    }
}
