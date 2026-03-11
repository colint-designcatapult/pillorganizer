package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceTenantMappingEntity
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

// @relation(CTRL-REQ-16, scope=file)
@MicronautTest
class DeviceTenantMappingRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DeviceTenantMappingRepo repo

    def "should get DeviceTenantMapping by serial number"() {
        given:
        def tenantId = "tenant-1"
        def serialNumber = "SN-123"

        this.insertDeviceTenantMapping(serialNumber, tenantId)

        when:
        def mapping = repo.findBySerialNumber(serialNumber)

        then:
        mapping.isPresent()
        mapping.get().tenantId == tenantId
        mapping.get().serialNumber == serialNumber
    }

    def "should save DeviceTenantMapping"() {
        given:
        def tenantId = "tenant-1"
        def serialNumber = "SN-NEW"

        def mapping = DeviceTenantMappingEntity.builder()
                .base(DeviceTenantMappingEntity.buildBase(serialNumber, tenantId))
                .tenantId(tenantId)
                .serialNumber(serialNumber)
                .build()

        when:
        repo.save(mapping)

        then:
        def savedMapping = repo.findBySerialNumber(serialNumber)
        savedMapping.isPresent()
        savedMapping.get().tenantId == tenantId
        savedMapping.get().serialNumber == serialNumber
        savedMapping.get().base.entityType == DeviceControlPlaneEntityType.DEVICE_TENANT_MAPPING
    }

    def "should find all serial numbers for a tenant"() {
        given:
        def tenantId = "tenant-A"
        this.insertDeviceTenantMapping("SN-1", tenantId)
        this.insertDeviceTenantMapping("SN-2", tenantId)
        this.insertDeviceTenantMapping("SN-3", "tenant-B")

        when:
        def mappings = repo.findAllByTenantId(tenantId)

        then:
        mappings.size() == 2
        mappings.any { it.serialNumber == "SN-1" }
        mappings.any { it.serialNumber == "SN-2" }
        mappings.every { it.tenantId == tenantId }
    }

    def "should fail to find non-existent mapping"() {
        when:
        def mapping = repo.findBySerialNumber("SN-NONE")

        then:
        mapping.isEmpty()
    }
}
