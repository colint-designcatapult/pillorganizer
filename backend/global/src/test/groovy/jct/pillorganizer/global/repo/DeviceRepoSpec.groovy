package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DeviceRepo repo

    def "should get Device by serial number"() {
        given:
        def tenantId = "tenant-1"
        def serialNumber = "SN-123"

        this.insertDevice(tenantId, serialNumber)

        when:
        def device = repo.findBySerialNumber(serialNumber)

        then:
        device.get().tenantId == tenantId
        device.get().serialNumber == serialNumber
    }

    def "should get Device by device id"() {
        given:
        def tenantId = "tenant-1"
        def serialNumber = "SN-123"
        def deviceId = "device-abc"

        this.insertDevice(tenantId, serialNumber, deviceId)

        when:
        def device = repo.findByDeviceId(deviceId)

        then:
        device.isPresent()
        device.get().deviceId == deviceId
        device.get().serialNumber == serialNumber
    }

    def "should get Devices by tenant id"() {
        given:
        def tenantId1 = "tenant-1"
        def tenantId2 = "tenant-2"
        def serialNumber1 = "SN-001"
        def serialNumber2 = "SN-002"
        def serialNumber3 = "SN-003"

        this.insertDevice(tenantId1, serialNumber1)
        this.insertDevice(tenantId1, serialNumber2)
        this.insertDevice(tenantId2, serialNumber3)

        when:
        def devices = repo.findByTenantId(tenantId1)

        then:
        devices.size() == 2
        devices.any { it.serialNumber == serialNumber1 && it.tenantId == tenantId1 }
        devices.any { it.serialNumber == serialNumber2 && it.tenantId == tenantId1 }
        devices.every { it.tenantId == tenantId1 }
    }

    def "should save Device"() {
        given:
        def tenantId = "tenant-1"
        def serialNumber = "SN-NEW"
        def deviceId = "device-new"

        def device = DeviceEntity.builder()
                .base(DeviceEntity.buildBase(serialNumber, tenantId, deviceId))
                .tenantId(tenantId)
                .serialNumber(serialNumber)
                .deviceId(deviceId)
                .build()

        when:
        repo.save(device)

        then:
        def savedDevice = repo.findBySerialNumber(serialNumber)
        savedDevice.get().tenantId == tenantId
        savedDevice.get().serialNumber == serialNumber
        savedDevice.get().deviceId == deviceId
        savedDevice.get().base.entityType == DeviceControlPlaneEntityType.DEVICE
        
        and:
        repo.findByDeviceId(deviceId).isPresent()
    }

    def "should fail to find non-existent Device"() {
        when:
        def device = repo.findBySerialNumber("device-does-not-exist")

        then:
        device.isEmpty()
    }
}
