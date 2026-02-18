package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.domain.model.ProvisioningStatus
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceMetadataRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbDeviceMetadataRepo repo

    def "should get device metadata by serial number"() {
        given:
        def serialNumber = "SN-123"
        def deviceId = "dev-1"
        def tenantId = "tenant-1"
        def modelId = "MODEL-A"
        def bootstrapKey = "key-123"
        def manufacturingDate = "2023-01-01"
        
        insertManufacturingRecord(serialNumber, modelId, bootstrapKey, manufacturingDate)
        insertDevice(deviceId, tenantId, serialNumber, modelId, ProvisioningStatus.ACTIVE)

        when:
        def result = repo.findBySerialNumber(serialNumber)

        then:
        result.isPresent()
        with(result.get()) {
            it.manufacturingRecord().serialNumber() == serialNumber
            it.manufacturingRecord().modelId() == modelId
            it.device().deviceId() == deviceId
            it.device().serialNumber() == serialNumber
        }
    }

    def "should return empty when manufacturing record not found"() {
        when:
        def result = repo.findBySerialNumber("non-existent-sn")

        then:
        result.isEmpty()
    }

    def "should return metadata with no device if device not assigned to tenant"() {
        given:
        def serialNumber = "SN-UNPROVISIONED"
        def modelId = "MODEL-B"
        
        insertManufacturingRecord(serialNumber, modelId, "key-456", "2023-02-01")

        when:
        def result = repo.findBySerialNumber(serialNumber)

        then:
        result.isPresent()
        with(result.get()) {
            it.manufacturingRecord().serialNumber() == serialNumber
            it.device() == null
        }
    }
    
    def "should throw exception when device exists but manufacturing record missing"() {
        given:
        def serialNumber = "SN-ORPHAN"
        def deviceId = "dev-orphan"
        
        insertDevice(deviceId, "tenant-1", serialNumber, "MODEL-C", ProvisioningStatus.ACTIVE)

        when:
        repo.findBySerialNumber(serialNumber)

        then:
        thrown(IllegalStateException)
    }
}
