package jct.pillorganizer.tenant.service

// @relation(CTRL-REQ-25, scope=file)
// @relation(CTRL-REQ-26, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(UN-603, scope=file)
// @relation(SYS-REQ-43, scope=file)
// @relation(SYS-REQ-44, scope=file)
// @relation(SYS-REQ-45, scope=file)
// @relation(SYS-REQ-46, scope=file)
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

    @Inject
    jct.pillorganizer.tenant.repo.LogicalDeviceRepository logicalDeviceRepository

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

    def "should disable device when primary user removes it"() {
        given:
        def user = userService.ensureExists("user-remove-1")
        def record = deviceService.provision(user, "device-remove-1", "serial-remove-1", "claim-remove-1", "thing-remove-1")
        def logicalDevice = record.logicalDevice

        when:
        deviceService.removeDevice(user, logicalDevice)

        then:
        def updatedDevice = logicalDeviceRepository.findById("device-remove-1")
        updatedDevice.isPresent()
        updatedDevice.get().disabledAt != null
    }

    def "should remove DeviceUser when non-primary user removes device"() {
        given:
        def primaryUser = userService.ensureExists("user-remove-primary")
        def secondaryUser = userService.ensureExists("user-remove-secondary")
        def record = deviceService.provision(primaryUser, "device-remove-2", "serial-remove-2", "claim-remove-2", "thing-remove-2")
        def logicalDevice = record.logicalDevice
        deviceService.addUserAccess(secondaryUser, logicalDevice)

        when:
        deviceService.removeDevice(secondaryUser, logicalDevice)

        then: "secondary user no longer has access"
        def access = deviceService.getUserAccess(secondaryUser, logicalDevice)
        access.isEmpty()

        and: "device is NOT disabled"
        def device = logicalDeviceRepository.findById("device-remove-2")
        device.isPresent()
        device.get().disabledAt == null
    }

    def "getUserDevices should filter out disabled devices"() {
        given:
        def user = userService.ensureExists("user-filter-1")
        def record = deviceService.provision(user, "device-filter-1", "serial-filter-1", "claim-filter-1", "thing-filter-1")
        def logicalDevice = record.logicalDevice

        when: "device is disabled"
        deviceService.disableDevice(logicalDevice)

        then: "getUserDevices should not return it"
        def devices = deviceService.getUserDevices(user)
        devices.findAll { it.deviceId() == "device-filter-1" }.isEmpty()
    }
}
