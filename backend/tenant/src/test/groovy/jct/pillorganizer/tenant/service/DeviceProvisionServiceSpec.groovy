package jct.pillorganizer.tenant.service

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.device.DeviceClass
import spock.lang.Subject

@MicronautTest
class DeviceProvisionServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceProvisionService deviceProvisionService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    KsuidService ksuidService;

    def "should provision a device"() {
        given:
        def user = userService.ensureExists("user-1")

        when:
        def record = deviceProvisionService.provision(user, "device-1", "serial-1", "token-1")

        then:
        record != null
        record.deviceId == "device-1"
        record.serialNo == "serial-1"
        record.claimToken == "token-1"
        record.deviceClass == DeviceClass.v1_7x2
        record.provisionedBy.id == user.id
    }

    def "should find provision record by claim token"() {
        given:
        def claimToken = "test-token-1"
        def user = userService.ensureExists("user-2")
        deviceProvisionService.provision(user, "device-2", "serial-2", claimToken)

        when:
        def record = deviceProvisionService.findByClaimToken(user, claimToken)
        def unassigned = deviceProvisionService.findUnassignedProvisionRecord(user)

        then:
        record.isPresent()
        record.get().deviceId == "device-2"
        record.get().claimToken == claimToken
        record.get().logicalDevice == null
        unassigned.size() == 1
        unassigned[0].deviceId == "device-2"
    }

    def "should not find unassigned provision record if already assigned"() {
        given:
        def user = userService.ensureExists("user-3")
        def record = deviceProvisionService.provision(user, "device-3", "serial-3", "token-3")
        deviceService.create(user, record)

        when:
        def foundRecord = deviceProvisionService.findUnassignedProvisionRecord(user)

        then:
        foundRecord.isEmpty()
    }

    def "should get provision records for logical device"() {
        given:
        def user = userService.ensureExists("user-4")
        def record = deviceProvisionService.provision(user, "device-4", "serial-4", "token-4")
        def logicalDevice = deviceService.create(user, record)

        when:
        def records = deviceProvisionService.getProvisionRecords(logicalDevice)

        then:
        records.size() == 1
        records[0].deviceId == "device-4"
    }

    def "should assign to logical device"() {
        given:
        def user = userService.ensureExists("user-5")
        def record = deviceProvisionService.provision(user, "device-5", "serial-5", "token-5")
        def logicalDevice = deviceService.create(user, record) // This already calls assignActiveLogicalDevice

        when:
        deviceProvisionService.assignToLogicalDevice(record, logicalDevice)

        then:
        record.logicalDevice.id == logicalDevice.id
    }

    def "should assign active logical device and disable others"() {
        given:
        def user = userService.ensureExists("user-6")
        def record1 = deviceProvisionService.provision(user, "device-6-1", "serial-6-1", "token-6-1")
        def logicalDevice = deviceService.create(user, record1)

        def record2 = deviceProvisionService.provision(user, "device-6-2", "serial-6-2", "token-6-2")

        when:
        deviceProvisionService.assignActiveLogicalDevice(record2, logicalDevice)

        then:
        record2.logicalDevice.id == logicalDevice.id
        record2.disabledAt == null

        and: "the first record should be disabled"
        def records = deviceProvisionService.getProvisionRecords(logicalDevice)
        def r1 = records.find { it.deviceId == "device-6-1" }
        r1.disabledAt != null
    }
}
