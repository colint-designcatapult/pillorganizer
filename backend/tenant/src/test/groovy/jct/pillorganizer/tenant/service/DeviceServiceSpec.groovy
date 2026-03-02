package jct.pillorganizer.tenant.service

import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.exceptions.DeviceAccessException
import spock.lang.Subject

@MicronautTest
class DeviceServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceService deviceService

    @Inject
    UserService userService

    @Inject
    DeviceProvisionService deviceProvisionService

    @Inject
    TenantService tenantService

    @MockBean(TenantService)
    TenantService tenantService() {
        Mock(TenantService)
    }

    def "should create a logical device from a provision record"() {
        given:
        def user = userService.ensureExists("user-1")
        def record = deviceProvisionService.provision(user, "device-1", "serial-1", "token-1")

        when:
        def logicalDevice = deviceService.create(user, record)

        then:
        logicalDevice != null
        logicalDevice.id != null
        logicalDevice.physicalDevice.deviceId == "device-1"

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
        def record = deviceProvisionService.provision(user1, "device-1-1", "serial-1-1", "token-1-1")

        when:
        deviceService.create(user2, record)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Provision record doesn't match user"
    }

    def "should fail to create a logical device if already assigned"() {
        given:
        def user = userService.ensureExists("user-1-3")
        def record = deviceProvisionService.provision(user, "device-1-3", "serial-1-3", "token-1-3")
        deviceService.create(user, record)

        when:
        deviceService.create(user, record)

        then:
        def e = thrown(IllegalStateException)
        e.message == "Device already assigned"
    }

    def "should get a logical device by id"() {
        given:
        def user = userService.ensureExists("user-2")
        def record = deviceProvisionService.provision(user, "device-2", "serial-2", "token-2")
        def created = deviceService.create(user, record)

        when:
        def found = deviceService.get(created.id)

        then:
        found.isPresent()
        found.get().id == created.id
    }

    def "should assign a new active physical device to a logical device"() {
        given:
        def user = userService.ensureExists("user-3")
        def record1 = deviceProvisionService.provision(user, "device-3-1", "serial-3-1", "token-3-1")
        def logicalDevice = deviceService.create(user, record1)

        def record2 = deviceProvisionService.provision(user, "device-3-2", "serial-3-2", "token-3-2")

        when:
        deviceService.assignActivePhysicalDevice(logicalDevice, record2)

        then:
        logicalDevice.physicalDevice.deviceId == "device-3-2"

        and: "the new record should be linked to the logical device"
        record2.logicalDevice.id == logicalDevice.id

        and: "the old record should be disabled"
        def records = deviceProvisionService.getProvisionRecords(logicalDevice)
        def r1 = records.find { it.deviceId == "device-3-1" }
        r1.disabledAt != null
    }

    def "should assign existing logical device to a new provision record"() {
        given:
        def user = userService.ensureExists("user-3-3")
        def record1 = deviceProvisionService.provision(user, "device-3-3-1", "serial-3-3-1", "token-3-3-1")
        def logicalDevice = deviceService.create(user, record1)

        def record2 = deviceProvisionService.provision(user, "device-3-3-2", "serial-3-3-2", "token-3-3-2")

        when:
        def result = deviceService.assignExisting(user, record2, logicalDevice.id.toString())

        then:
        result.id == logicalDevice.id
        result.physicalDevice.deviceId == "device-3-3-2"
        record2.logicalDevice.id == logicalDevice.id
    }

    def "should fail to assign existing if record is already assigned"() {
        given:
        def user = userService.ensureExists("user-3-4")
        def record1 = deviceProvisionService.provision(user, "device-3-4-1", "serial-3-4-1", "token-3-4-1")
        def logicalDevice = deviceService.create(user, record1)

        when:
        deviceService.assignExisting(user, record1, logicalDevice.id.toString())

        then:
        def e = thrown(IllegalStateException)
        e.message == "Device already assigned"
    }

    def "should fail to assign existing if user has no access"() {
        given:
        def user1 = userService.ensureExists("user-3-5-1")
        def user2 = userService.ensureExists("user-3-5-2")
        def record1 = deviceProvisionService.provision(user1, "device-3-5-1", "serial-3-5-1", "token-3-5-1")
        def logicalDevice = deviceService.create(user1, record1)

        def record2 = deviceProvisionService.provision(user2, "device-3-5-2", "serial-3-5-2", "token-3-5-2")

        when:
        deviceService.assignExisting(user2, record2, logicalDevice.id.toString())

        then:
        def e = thrown(DeviceAccessException)
        e.message == "User has no access to device"
    }

    def "should fail to assign existing if user is not primary"() {
        given:
        def user1 = userService.ensureExists("user-3-6-1")
        def user2 = userService.ensureExists("user-3-6-2")
        def record1 = deviceProvisionService.provision(user1, "device-3-6-1", "serial-3-6-1", "token-3-6-1")
        def logicalDevice = deviceService.create(user1, record1)

        deviceService.addUserAccess(user2, logicalDevice)
        def record2 = deviceProvisionService.provision(user2, "device-3-6-2", "serial-3-6-2", "token-3-6-2")

        when:
        deviceService.assignExisting(user2, record2, logicalDevice.id.toString())

        then:
        def e = thrown(DeviceAccessException)
        e.message == "User is not primary user of the device"
    }

    def "should manage user access to device"() {
        given:
        def user = userService.ensureExists("user-4")
        def record = deviceProvisionService.provision(user, "device-4", "serial-4", "token-4")
        def logicalDevice = deviceService.create(user, record)

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
        def record = deviceProvisionService.provision(user1, "device-5", "serial-5", "token-5")
        def logicalDevice = deviceService.create(user1, record)

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
        def record1 = deviceProvisionService.provision(user1, "device-6-1", "serial-6-1", "token-6-1")
        def record2 = deviceProvisionService.provision(user1, "device-6-2", "serial-6-2", "token-6-2")
        def ld1 = deviceService.create(user1, record1)
        def ld2 = deviceService.create(user1, record2)

        and: "grant user2 access to ld1"
        deviceService.addUserAccess(user2, ld1)

        and:
        def tenant = new TenantDetails("test-tenant", true, "localhost", "http://localhost")

        when: "getting devices for user1"
        def devices1 = deviceService.getUserDevices(user1)

        then:
        1 * tenantService.getCurrentTenant() >> Optional.of(tenant)
        devices1.size() == 2
        devices1.find { it.id() == ld1.id.toString() }.primaryUser()
        devices1.find { it.id() == ld2.id.toString() }.primaryUser()

        when: "getting devices for user2"
        def devices2 = deviceService.getUserDevices(user2)

        then:
        1 * tenantService.getCurrentTenant() >> Optional.of(tenant)
        devices2.size() == 1
        devices2.find { it.id() == ld1.id.toString() } != null
        !devices2.find { it.id() == ld1.id.toString() }.primaryUser()
    }
}
