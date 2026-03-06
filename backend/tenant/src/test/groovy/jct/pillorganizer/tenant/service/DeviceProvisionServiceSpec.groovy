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
        def record = deviceService.provision(user, "device-1", "serial-1", "claim-1", "thing-1")

        then:
        record != null
        record.logicalDevice.id == "device-1"
        record.serialNo == "serial-1"
        record.claimId == "claim-1"
        record.deviceClass == DeviceClass.v1_7x2
        record.provisionedBy.id == user.id
    }

    def "should find provision record by claim id"() {
        given:
        def claimId = "test-claim-1"
        def user = userService.ensureExists("user-2")
        deviceService.provision(user, "device-2", "serial-2", claimId, "thing-2")

        when:
        def record = deviceService.findByClaimId(claimId)

        then:
        record.isPresent()
        record.get().logicalDevice.id == "device-2"
        record.get().claimId == claimId
    }

    def "should return false claim eligibility if not primary user"() {
        given:
        def user1 = userService.ensureExists("user-3")
        def user2 = userService.ensureExists("user-4")
        def record = deviceService.provision(user1, "device-3", "serial-3", "claim-3", "thing-3")
        
        and: "add user2 as non-primary access"
        deviceService.addUserAccess(user2, record.logicalDevice)

        when:
        def eligibility = deviceService.getDeviceClaimEligibility(user2, "serial-3", "device-3")

        then:
        !eligibility.isEligible()
    }

    def "should get provision records for logical device"() {
        given:
        def user = userService.ensureExists("user-4")
        def record = deviceService.provision(user, "device-4", "serial-4", "claim-4", "thing-4")
        def logicalDevice = record.logicalDevice

        when:
        def records = deviceService.getProvisionRecords(logicalDevice)

        then:
        records.size() == 1
        records[0].logicalDevice.id == "device-4"
    }

    def "should assign to logical device"() {
        given:
        def user = userService.ensureExists("user-5")
        def record = deviceService.provision(user, "device-5", "serial-5", "claim-5", "thing-5")
        def logicalDevice = record.logicalDevice

        when:
        deviceService.assignToLogicalDevice(record, logicalDevice)

        then:
        record.logicalDevice.id == logicalDevice.id
    }

    def "should assign active logical device and disable others"() {
        given:
        def user = userService.ensureExists("user-6")
        def record1 = deviceService.provision(user, "device-6-1", "serial-6-1", "claim-6-1", "thing-6-1")
        def logicalDevice = record1.logicalDevice

        def record2 = deviceService.provision(user, "device-6-1", "serial-6-2", "claim-6-2", "thing-6-2")

        when:
        deviceService.assignActiveLogicalDevice(record2, logicalDevice)

        then:
        record2.logicalDevice.id == logicalDevice.id
        record2.disabledAt == null

        and: "the first record should be disabled"
        def records = deviceService.getProvisionRecords(logicalDevice)
        def r1 = records.find { it.claimId == "claim-6-1" }
        r1.disabledAt != null
    }
}
