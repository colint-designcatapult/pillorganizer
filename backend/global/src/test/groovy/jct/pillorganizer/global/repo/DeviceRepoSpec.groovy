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

    // ── findAllPaginated ──────────────────────────────────────────────────────

    def "findAllPaginated should return first page and a non-null cursor when more devices exist"() {
        given: "three DEVICE entities in the table"
        insertDevice("tenant-1", "SN-P1", "device-p1")
        insertDevice("tenant-1", "SN-P2", "device-p2")
        insertDevice("tenant-1", "SN-P3", "device-p3")

        when: "the first page is requested with page size 2"
        def result = repo.findAllPaginated(2, null)

        then: "exactly 2 devices are returned"
        result.items().size() == 2

        and: "a cursor is present to fetch the remaining device"
        result.nextCursor() != null
    }

    def "findAllPaginated should traverse all devices across pages via cursor"() {
        given:
        insertDevice("tenant-1", "SN-T1", "device-t1")
        insertDevice("tenant-1", "SN-T2", "device-t2")
        insertDevice("tenant-1", "SN-T3", "device-t3")

        when:
        def page1 = repo.findAllPaginated(2, null)
        def page2 = repo.findAllPaginated(2, page1.nextCursor())

        then: "combined results cover all three devices without duplication"
        def allSerials = (page1.items() + page2.items()).collect { it.serialNumber }
        allSerials.size() == 3
        allSerials.containsAll(["SN-T1", "SN-T2", "SN-T3"])

        and: "second page has the remaining device and signals end-of-results"
        page2.items().size() == 1
        page2.nextCursor() == null
    }

    def "findAllPaginated should return null cursor when all devices fit in one scan page"() {
        given:
        insertDevice("tenant-1", "SN-F1", "device-f1")
        insertDevice("tenant-1", "SN-F2", "device-f2")

        when:
        def result = repo.findAllPaginated(10, null)

        then:
        result.items().size() == 2
        result.nextCursor() == null
    }

    def "findAllPaginated should exclude non-DEVICE entities from results"() {
        given: "two devices and a user entity in the same table"
        insertDevice("tenant-1", "SN-D1", "device-d1")
        insertDevice("tenant-1", "SN-D2", "device-d2")
        insertUser("user-extra", "Extra User", "sub-extra")

        when: "page size larger than total items so all are evaluated in one scan"
        def result = repo.findAllPaginated(20, null)

        then: "only DEVICE entities are returned"
        result.items().size() == 2
        result.items().every { it.serialNumber.startsWith("SN-D") }
        result.nextCursor() == null
    }

    def "findAllPaginated should return empty list and null cursor when no devices exist"() {
        when:
        def result = repo.findAllPaginated(20, null)

        then:
        result.items().isEmpty()
        result.nextCursor() == null
    }
}

