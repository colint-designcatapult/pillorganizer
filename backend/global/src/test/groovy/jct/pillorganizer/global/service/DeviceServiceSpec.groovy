package jct.pillorganizer.global.service

// @relation(CTRL-REQ-16, scope=file)
// @relation(UN-602, scope=file)
// @relation(UN-7309, scope=file)
// @relation(SYS-REQ-15, scope=file)
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

    // @relation(CTRL-REQ-16, scope=range_start)
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
    // @relation(CTRL-REQ-16, scope=range_end)

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
