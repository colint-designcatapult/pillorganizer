package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.model.ProvisioningStatus
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DeviceRepo repo

    def "should get Device by id"() {
        given:
        def deviceId = "device-1"
        def tenantId = "tenant-1"
        def serialNumber = "SN-123"
        def modelId = "MODEL-X"
        def status = ProvisioningStatus.ACTIVE

        this.insertDevice(deviceId, tenantId, serialNumber, modelId, status)

        when:
        def device = repo.findByDeviceId(deviceId)

        then:
        device.get().deviceId == deviceId
        device.get().tenantId == tenantId
        device.get().serialNumber == serialNumber
        device.get().modelId == modelId
        device.get().provisioningStatus == status
    }

    def "should get Devices by serial number"() {
        given:
        def deviceId1 = "device-1"
        def deviceId2 = "device-2"
        def tenantId = "tenant-1"
        def serialNumber = "SN-123"
        def modelId = "MODEL-X"
        def status = ProvisioningStatus.ACTIVE

        this.insertDevice(deviceId1, tenantId, serialNumber, modelId, status)
        this.insertDevice(deviceId2, tenantId, serialNumber, modelId, status)

        when:
        def devices = repo.findBySerialNumber(serialNumber)

        then:
        devices.size() == 2
        devices.any { it.deviceId == deviceId1 && it.serialNumber == serialNumber }
        devices.any { it.deviceId == deviceId2 && it.serialNumber == serialNumber }
    }

    def "should get Devices by tenant id"() {
        given:
        def deviceId1 = "device-1"
        def deviceId2 = "device-2"
        def deviceId3 = "device-3"
        def tenantId1 = "tenant-1"
        def tenantId2 = "tenant-2"
        def serialNumber1 = "SN-001"
        def serialNumber2 = "SN-002"
        def serialNumber3 = "SN-003"
        def modelId = "MODEL-X"
        def status = ProvisioningStatus.ACTIVE

        this.insertDevice(deviceId1, tenantId1, serialNumber1, modelId, status)
        this.insertDevice(deviceId2, tenantId1, serialNumber2, modelId, status)
        this.insertDevice(deviceId3, tenantId2, serialNumber3, modelId, status)

        when:
        def devices = repo.findByTenantId(tenantId1)

        then:
        devices.size() == 2
        devices.any { it.deviceId == deviceId1 && it.tenantId == tenantId1 }
        devices.any { it.deviceId == deviceId2 && it.tenantId == tenantId1 }
        devices.every { it.tenantId == tenantId1 }
    }

    def "should save Device"() {
        given:
        def deviceId = "device-new"
        def tenantId = "tenant-1"
        def serialNumber = "SN-NEW"
        def modelId = "MODEL-Y"
        def status = ProvisioningStatus.ASSIGNED

        def device = DeviceEntity.builder()
                .base(DeviceEntity.buildBase(deviceId, serialNumber, tenantId))
                .deviceId(deviceId)
                .tenantId(tenantId)
                .serialNumber(serialNumber)
                .modelId(modelId)
                .provisioningStatus(status)
                .build()

        when:
        repo.save(device)

        then:
        def savedDevice = repo.findByDeviceId(deviceId)
        savedDevice.get().deviceId == deviceId
        savedDevice.get().tenantId == tenantId
        savedDevice.get().serialNumber == serialNumber
        savedDevice.get().modelId == modelId
        savedDevice.get().provisioningStatus == status
        savedDevice.get().base.entityType == DeviceControlPlaneEntityType.DEVICE
    }

    def "should fail to find non-existent Device"() {
        when:
        def device = repo.findByDeviceId("device-does-not-exist")

        then:
        device.isEmpty()
    }
}
