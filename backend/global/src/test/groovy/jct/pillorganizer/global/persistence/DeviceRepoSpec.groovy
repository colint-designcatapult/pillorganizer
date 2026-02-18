package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.domain.model.ProvisioningStatus
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbDeviceRepo repo

    def "should get device by id"() {
        given:
        def deviceId = "dev-123"
        def tenantId = "tenant-1"
        def serialNumber = "SN-001"
        def modelId = "MODEL-X"
        
        insertDevice(deviceId, tenantId, serialNumber, modelId, ProvisioningStatus.ACTIVE)

        when:
        def result = repo.get(deviceId)

        then:
        result.isPresent()
        with(result.get()) {
            it.deviceId() == deviceId
            it.tenantId() == tenantId
            it.serialNumber() == serialNumber
            it.modelId() == modelId
            it.provisioningStatus() == ProvisioningStatus.ACTIVE
            it.version() == 1
        }
    }

    def "should return empty when device not found"() {
        when:
        def result = repo.get("non-existent-device")

        then:
        result.isEmpty()
    }

    def "should find device by serial number"() {
        given:
        def deviceId = "dev-456"
        def tenantId = "tenant-2"
        def serialNumber = "SN-002"
        def modelId = "MODEL-Y"
        
        insertDevice(deviceId, tenantId, serialNumber, modelId, ProvisioningStatus.ACTIVE)

        when:
        def result = repo.findBySerialNumber(serialNumber)

        then:
        result.isPresent()
        with(result.get()) {
            it.deviceId() == deviceId
            it.serialNumber() == serialNumber
            it.modelId() == modelId
        }
    }

    def "should return empty when device with serial number not found"() {
        when:
        def result = repo.findBySerialNumber("non-existent-sn")

        then:
        result.isEmpty()
    }
}
