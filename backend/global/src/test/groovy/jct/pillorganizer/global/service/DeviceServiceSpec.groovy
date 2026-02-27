package jct.pillorganizer.global.service

import jct.pillorganizer.global.model.DeviceTenantMappingEntity
import jct.pillorganizer.global.repo.DeviceTenantMappingRepo
import spock.lang.Specification
import spock.lang.Subject

class DeviceServiceSpec extends Specification {

    DeviceTenantMappingRepo deviceTenantMappingRepo = Mock()
    String defaultTenant = "default-tenant"

    @Subject
    DeviceService deviceService = new DeviceService(
            deviceTenantMappingRepo: deviceTenantMappingRepo,
            defaultTenant: defaultTenant
    )

    def "should lookup tenant from mapping"() {
        given:
        def serialNumber = "SN-123"
        def tenantId = "tenant-A"
        def mapping = DeviceTenantMappingEntity.builder()
                .tenantId(tenantId)
                .serialNumber(serialNumber)
                .build()

        and:
        deviceTenantMappingRepo.findBySerialNumber(serialNumber) >> Optional.of(mapping)

        when:
        def result = deviceService.lookupTenant(serialNumber)

        then:
        result == tenantId
    }

    def "should return default tenant if no mapping exists"() {
        given:
        def serialNumber = "SN-UNKNOWN"

        and:
        deviceTenantMappingRepo.findBySerialNumber(serialNumber) >> Optional.empty()

        when:
        def result = deviceService.lookupTenant(serialNumber)

        then:
        result == defaultTenant
    }
}
