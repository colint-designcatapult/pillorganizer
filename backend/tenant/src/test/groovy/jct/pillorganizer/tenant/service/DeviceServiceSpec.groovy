package jct.pillorganizer.tenant.service

// @relation(CTRL-REQ-11, scope=file)
// @relation(CTRL-REQ-25, scope=file)
// @relation(UN-201, scope=file)
// @relation(UN-202, scope=file)
// @relation(UN-204, scope=file)
// @relation(UN-305, scope=file)
// @relation(UN-307, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(SYS-REQ-27, scope=file)
// @relation(SYS-REQ-36, scope=file)
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.exceptions.DeviceAccessException
import jct.pillorganizer.tenant.model.device.ProvisionRecord
import spock.lang.Subject

@MicronautTest
class DeviceServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceService deviceService

    @Inject
    UserService userService

    @Inject
    jct.pillorganizer.tenant.repo.ProvisionRecordRepository provisionRecordRepository

    @Inject
    TenantService tenantService

    @MockBean(TenantService)
    TenantService tenantService() {
        Mock(TenantService)
    }

    def "should create a logical device from a provision record"() {
        given:
        def user = userService.ensureExists("user-1")

        when:
        def record = deviceService.provision(user, "device-1", "serial-1", "claim-1", "thing-1")
        def logicalDevice = record.logicalDevice

        then:
        logicalDevice != null
        logicalDevice.id != null

        and: "the provision record should be updated with the logical device"
        record.logicalDevice.id == logicalDevice.id

        and: "the user should be the primary user"
        def access = deviceService.getUserAccess(user, logicalDevice)
        access.isPresent()
        access.get().primaryUser
    }

    def "should fail to create a logical device if provisioned by another user"() {
        given:
        def user1 = userService.ensureExists("user-1-1")
        def user2 = userService.ensureExists("user-1-2")
        def record = deviceService.provision(user1, "device-1-1", "serial-1-1", "claim-1-1", "thing-1-1")

        when:
        deviceService.provision(user2, "device-1-1", "serial-1-2", "claim-1-2", "thing-1-2")

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Not eligible to claim device"
    }

    def "should fail to assign existing if already assigned"() {
        given:
        def user = userService.ensureExists("user-1-3")
        def record = deviceService.provision(user, "device-1-3", "serial-1-3", "claim-1-3", "thing-1-3")
        def logicalDevice = record.logicalDevice

        when:
        deviceService.assignExisting(user, record, logicalDevice.id)

        then:
        def e = thrown(IllegalStateException)
        e.message == "Device already assigned"
    }

    def "should get a logical device by id"() {
        given:
        def user = userService.ensureExists("user-2")
        def record = deviceService.provision(user, "device-2", "serial-2", "claim-2", "thing-2")
        def created = record.logicalDevice

        when:
        def found = deviceService.get(created.id)

        then:
        found.isPresent()
        found.get().id == created.id
    }

    def "should assign a new active physical device to a logical device"() {
        given:
        def user = userService.ensureExists("user-3")
        def record1 = deviceService.provision(user, "device-3-1", "serial-3-1", "claim-3-1", "thing-3-1")

        when:
        def record2 = deviceService.provision(user, "device-3-1", "serial-3-2", "claim-3-2", "thing-3-2")
        def logicalDevice = deviceService.get("device-3-1").get()

        then:
        logicalDevice.physicalDevice.claimId == "claim-3-2"

        and: "the new record should be linked to the logical device"
        record2.logicalDevice.id == logicalDevice.id

        and: "the old record should be disabled"
        def records = deviceService.getProvisionRecords(logicalDevice)
        def r1 = records.find { it.claimId == "claim-3-1" }
        r1.disabledAt != null
    }

    def "should assign existing logical device to a new provision record"() {
        given:
        def user = userService.ensureExists("user-3-3")
        def record1 = deviceService.provision(user, "device-3-3-1", "serial-3-3-1", "claim-3-3-1", "thing-3-3-1")
        def logicalDevice = record1.logicalDevice

        def record2 = new ProvisionRecord(claimId: "claim-3-3-2", serialNo: "serial-3-3-2", thingName: "thing-3-3-2", provisionedBy: user)
        provisionRecordRepository.save(record2)

        when:
        def result = deviceService.assignExisting(user, record2, logicalDevice.id)

        then:
        result.id == logicalDevice.id
        result.physicalDevice.claimId == "claim-3-3-2"
        record2.logicalDevice.id == logicalDevice.id
    }

    def "should fail to assign existing logically assigned record"() {
        given:
        def user = userService.ensureExists("user-3-4")
        def record1 = deviceService.provision(user, "device-3-4-1", "serial-3-4-1", "claim-3-4-1", "thing-3-4-1")
        def logicalDevice = record1.logicalDevice

        when:
        deviceService.assignExisting(user, record1, logicalDevice.id)

        then:
        def e = thrown(IllegalStateException)
        e.message == "Device already assigned"
    }

    def "should fail to assign existing if user has no access"() {
        given:
        def user1 = userService.ensureExists("user-3-5-1")
        def user2 = userService.ensureExists("user-3-5-2")
        def record1 = deviceService.provision(user1, "device-3-5-1", "serial-3-5-1", "claim-3-5-1", "thing-3-5-1")
        def logicalDevice = record1.logicalDevice

        def record2 = new ProvisionRecord(claimId: "claim-3-5-2", serialNo: "serial-3-5-2", thingName: "thing-3-5-2", provisionedBy: user2)
        provisionRecordRepository.save(record2)

        when:
        deviceService.assignExisting(user2, record2, logicalDevice.id)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "User has no access to device"
    }

    def "should fail to assign existing if user is not primary"() {
        given:
        def user1 = userService.ensureExists("user-3-6-1")
        def user2 = userService.ensureExists("user-3-6-2")
        def record1 = deviceService.provision(user1, "device-3-6-1", "serial-3-6-1", "claim-3-6-1", "thing-3-6-1")
        def logicalDevice = record1.logicalDevice

        deviceService.addUserAccess(user2, logicalDevice)
        def record2 = new ProvisionRecord(claimId: "claim-3-6-2", serialNo: "serial-3-6-2", thingName: "thing-3-6-2", provisionedBy: user2)
        provisionRecordRepository.save(record2)

        when:
        deviceService.assignExisting(user2, record2, logicalDevice.id)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "User is not primary user of the device"
    }

    def "should manage user access to device"() {
        given:
        def user = userService.ensureExists("user-4")
        def record = deviceService.provision(user, "device-4", "serial-4", "claim-4", "thing-4")
        def logicalDevice = record.logicalDevice

        when: "adding user access"
        deviceService.addUserAccess(user, logicalDevice)

        then: "access should be granted"
        def access = deviceService.getUserAccess(user, logicalDevice)
        access.isPresent()
        access.get().primaryUser // create() sets primary user
        access.get().user.id == user.id
        access.get().device.id == logicalDevice.id

        when: "adding access again"
        deviceService.addUserAccess(user, logicalDevice)

        then: "nothing should change"
        deviceService.getUserAccess(user, logicalDevice).isPresent()

        when: "removing user access"
        deviceService.removeUserAccess(user, logicalDevice)

        then: "access should be removed"
        deviceService.getUserAccess(user, logicalDevice).isEmpty()
    }

    def "should set primary user and clear others"() {
        given:
        def user1 = userService.ensureExists("user-5-1")
        def user2 = userService.ensureExists("user-5-2")
        def record = deviceService.provision(user1, "device-5", "serial-5", "claim-5", "thing-5")
        def logicalDevice = record.logicalDevice

        deviceService.addUserAccess(user1, logicalDevice)
        deviceService.addUserAccess(user2, logicalDevice)

        when: "setting user 1 as primary"
        deviceService.setPrimaryUser(logicalDevice, user1)

        then:
        deviceService.getUserAccess(user1, logicalDevice).get().primaryUser
        !deviceService.getUserAccess(user2, logicalDevice).get().primaryUser

        when: "setting user 2 as primary"
        deviceService.setPrimaryUser(logicalDevice, user2)

        then:
        !deviceService.getUserAccess(user1, logicalDevice).get().primaryUser
        deviceService.getUserAccess(user2, logicalDevice).get().primaryUser
    }

    def "should get user devices"() {
        given:
        def user1 = userService.ensureExists("user-6-1")
        def user2 = userService.ensureExists("user-6-2")
        def record1 = deviceService.provision(user1, "device-6-1", "serial-6-1", "claim-6-1", "thing-6-1")
        def record2 = deviceService.provision(user1, "device-6-2", "serial-6-2", "claim-6-2", "thing-6-2")
        def ld1 = record1.logicalDevice
        def ld2 = record2.logicalDevice

        and: "grant user2 access to ld1"
        deviceService.addUserAccess(user2, ld1)

        and:
        def tenant = TenantDetails.TEST_TENANT

        when: "getting devices for user1"
        def devices1 = deviceService.getUserDevices(user1)

        then:
        1 * tenantService.getCurrentTenant() >> Optional.of(tenant)
        devices1.size() == 2
        devices1.find { it.deviceId() == ld1.id.toString() }.primaryUser()
        devices1.find { it.deviceId() == ld2.id.toString() }.primaryUser()

        when: "getting devices for user2"
        def devices2 = deviceService.getUserDevices(user2)

        then:
        1 * tenantService.getCurrentTenant() >> Optional.of(tenant)
        devices2.size() == 1
        devices2.find { it.deviceId() == ld1.id.toString() } != null
        !devices2.find { it.deviceId() == ld1.id.toString() }.primaryUser()
    }

    def "should return eligible when device does not exist for claim eligibility"() {
        given:
        def user = userService.ensureExists("user-claim-1")
        def deviceId = "non-existent-device-123"

        when:
        def eligibility = deviceService.getDeviceClaimEligibility(user, "serial-123", deviceId)

        then:
        eligibility.isEligible()
        eligibility.device().isEmpty()
    }

    def "should return eligible when user is primary for claim eligibility"() {
        given:
        def user = userService.ensureExists("user-claim-2")
        def deviceId = "device-claim-2"
        def record = deviceService.provision(user, deviceId, "serial-claim-2", "claim-token-2", "thing-2")

        when:
        def eligibility = deviceService.getDeviceClaimEligibility(user, "serial-claim-2", record.logicalDevice.id)

        then:
        eligibility.isEligible()
        eligibility.device().isPresent()
        eligibility.device().get().id == record.logicalDevice.id
    }

    def "should update device nickname successfully"() {
        given:
        def user = userService.ensureExists("user-nick-1")
        def record = deviceService.provision(user, "device-nick-1", "serial-nick-1", "claim-nick-1", "thing-nick-1")
        def logicalDevice = record.logicalDevice
        tenantService.getCurrentTenant() >> Optional.of(TenantDetails.TEST_TENANT)

        when:
        deviceService.updateNickname(logicalDevice, "My Pill Box")

        then:
        deviceService.get("device-nick-1").get().nickname == "My Pill Box"
    }

    def "should return not eligible when user is not primary for claim eligibility"() {
        given:
        def user1 = userService.ensureExists("user-claim-3")
        def user2 = userService.ensureExists("user-claim-4")
        def deviceId = "device-claim-3"
        def record = deviceService.provision(user1, deviceId, "serial-claim-3", "claim-token-3", "thing-3")

        and: "grant user2 access"
        deviceService.addUserAccess(user2, record.logicalDevice)

        when:
        def eligibility = deviceService.getDeviceClaimEligibility(user2, "serial-claim-3", record.logicalDevice.id)

        then:
        !eligibility.isEligible()
        eligibility.device().isPresent()
        eligibility.device().get().id == record.logicalDevice.id
    }
}
