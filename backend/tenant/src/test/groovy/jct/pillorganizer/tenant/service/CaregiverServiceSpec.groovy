package jct.pillorganizer.tenant.service

// @relation(UN-302, scope=file)
// @relation(UN-303, scope=file)
// @relation(UN-304, scope=file)
// @relation(UN-7312, scope=file)
// @relation(UN-504, scope=file)
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.exceptions.DeviceAccessException
import spock.lang.Subject

@MicronautTest
class CaregiverServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    CaregiverService caregiverService

    @Inject
    DeviceService deviceService

    @Inject
    UserService userService

    // -------------------------------------------------------------------------
    // inviteCaregiver
    // -------------------------------------------------------------------------

    def "inviteCaregiver should grant caregiver access with nickname"() {
        given:
        def patient = userService.ensureExists("cg-inv-1a")
        def record = deviceService.provision(patient, "cg-dev-inv-1", "sn-inv-1", "cl-inv-1", "th-inv-1")
        def device = record.logicalDevice

        when:
        caregiverService.inviteCaregiver(patient, device, "cg-inv-1b", "cg@example.com", "CG Name", "Grandma")

        then: "a new user was created and has access"
        def caregiver = userService.get("cg-inv-1b").get()
        deviceService.getUserAccess(caregiver, device).isPresent()
        !deviceService.getUserAccess(caregiver, device).get().primaryUser
        deviceService.getUserAccess(caregiver, device).get().nickname == "Grandma"
    }

    def "inviteCaregiver should fail if requester is not primary user"() {
        given:
        def patient = userService.ensureExists("cg-inv-2a")
        def caregiver1 = userService.ensureExists("cg-inv-2b")
        def record = deviceService.provision(patient, "cg-dev-inv-2", "sn-inv-2", "cl-inv-2", "th-inv-2")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver1, device)

        when: "non-primary user tries to invite"
        caregiverService.inviteCaregiver(caregiver1, device, "cg-inv-2c", "cg2@example.com", null, "Nurse")

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Only the primary user can invite caregivers"
    }

    def "inviteCaregiver should fail if caregiver already has access"() {
        given:
        def patient = userService.ensureExists("cg-inv-3a")
        def caregiver = userService.ensureExists("cg-inv-3b")
        def record = deviceService.provision(patient, "cg-dev-inv-3", "sn-inv-3", "cl-inv-3", "th-inv-3")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)

        when: "try to invite existing caregiver"
        caregiverService.inviteCaregiver(patient, device, "cg-inv-3b", "cg@example.com", null, "Nurse")

        then:
        def e = thrown(DeviceAccessException)
        e.message == "User already has access to this device"
    }

    def "inviteCaregiver should fail if requester has no access to device"() {
        given:
        def patient = userService.ensureExists("cg-inv-4a")
        def stranger = userService.ensureExists("cg-inv-4b")
        def record = deviceService.provision(patient, "cg-dev-inv-4", "sn-inv-4", "cl-inv-4", "th-inv-4")
        def device = record.logicalDevice

        when:
        caregiverService.inviteCaregiver(stranger, device, "cg-inv-4c", "cg@example.com", null, "Nurse")

        then:
        def e = thrown(DeviceAccessException)
        e.message == "No access to device"
    }

    // -------------------------------------------------------------------------
    // revokeCaregiver
    // -------------------------------------------------------------------------

    def "revokeCaregiver should remove caregiver access"() {
        given:
        def patient = userService.ensureExists("cg-rev-1a")
        def caregiver = userService.ensureExists("cg-rev-1b")
        def record = deviceService.provision(patient, "cg-dev-rev-1", "sn-rev-1", "cl-rev-1", "th-rev-1")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)
        def caregiverAccess = deviceService.getUserAccess(caregiver, device).get()

        when:
        caregiverService.revokeCaregiver(caregiverAccess.id, patient)

        then:
        deviceService.getUserAccess(caregiver, device).isEmpty()
    }

    def "revokeCaregiver should fail if requester is not primary user"() {
        given:
        def patient = userService.ensureExists("cg-rev-2a")
        def caregiver1 = userService.ensureExists("cg-rev-2b")
        def caregiver2 = userService.ensureExists("cg-rev-2c")
        def record = deviceService.provision(patient, "cg-dev-rev-2", "sn-rev-2", "cl-rev-2", "th-rev-2")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver1, device)
        deviceService.addUserAccess(caregiver2, device)
        def caregiver1Access = deviceService.getUserAccess(caregiver1, device).get()

        when: "caregiver2 tries to revoke caregiver1"
        caregiverService.revokeCaregiver(caregiver1Access.id, caregiver2)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Only the primary user can revoke caregiver access"
    }

    def "revokeCaregiver should fail when attempting to revoke the primary user"() {
        given:
        def patient = userService.ensureExists("cg-rev-3a")
        def caregiver = userService.ensureExists("cg-rev-3b")
        def record = deviceService.provision(patient, "cg-dev-rev-3", "sn-rev-3", "cl-rev-3", "th-rev-3")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)
        def patientAccess = deviceService.getUserAccess(patient, device).get()

        when: "caregiver attempts to revoke the primary user (themselves as requester doesn't matter — we're revoking the primary)"
        caregiverService.revokeCaregiver(patientAccess.id, caregiver)

        then:
        def e = thrown(DeviceAccessException)
        // caregiver is not primary, so this should fail with authorization error first
        e.message == "Only the primary user can revoke caregiver access"
    }

    def "revokeCaregiver should fail if target deviceUserId does not exist"() {
        given:
        def patient = userService.ensureExists("cg-rev-4")
        def nonExistentId = UUID.randomUUID()

        when:
        caregiverService.revokeCaregiver(nonExistentId, patient)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Caregiver not found"
    }

    // -------------------------------------------------------------------------
    // listCaregivers
    // -------------------------------------------------------------------------

    def "listCaregivers should return all users with access to the device"() {
        given:
        def patient = userService.ensureExists("cg-lstc-1a")
        def caregiver = userService.ensureExists("cg-lstc-1b")
        def record = deviceService.provision(patient, "cg-dev-lstc-1", "sn-lstc-1", "cl-lstc-1", "th-lstc-1")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)

        when:
        def list = caregiverService.listCaregivers(device.id, patient)

        then:
        list.size() == 2
        list.find { it.id() == deviceService.getUserAccess(patient, device).get().id }.primaryUser()
        !list.find { it.id() == deviceService.getUserAccess(caregiver, device).get().id }.primaryUser()
    }

    def "listCaregivers should always return a non-null userName even when user has no name or email"() {
        given: "a caregiver created with ensureExists (no name or email)"
        def patient = userService.ensureExists("cg-lstc-3a")
        def caregiver = userService.ensureExists("cg-lstc-3b")
        def record = deviceService.provision(patient, "cg-dev-lstc-3", "sn-lstc-3", "cl-lstc-3", "th-lstc-3")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)

        when:
        def list = caregiverService.listCaregivers(device.id, patient)

        then: "all entries have a non-null userName (falls back to user ID)"
        list.every { it.userName() != null }
        list.find { it.id() == deviceService.getUserAccess(caregiver, device).get().id }.userName() == "cg-lstc-3b"
    }

    def "listCaregivers should fail if requester has no access"() {
        given:
        def patient = userService.ensureExists("cg-lstc-2a")
        def stranger = userService.ensureExists("cg-lstc-2b")
        def record = deviceService.provision(patient, "cg-dev-lstc-2", "sn-lstc-2", "cl-lstc-2", "th-lstc-2")
        def device = record.logicalDevice

        when:
        caregiverService.listCaregivers(device.id, stranger)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "No access to device"
    }

    // -------------------------------------------------------------------------
    // transferPrimaryUser
    // -------------------------------------------------------------------------

    def "transferPrimaryUser should make target the new primary user"() {
        given:
        def patient = userService.ensureExists("cg-xfer-1a")
        def caregiver = userService.ensureExists("cg-xfer-1b")
        def record = deviceService.provision(patient, "cg-dev-xfer-1", "sn-xfer-1", "cl-xfer-1", "th-xfer-1")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)
        def caregiverAccess = deviceService.getUserAccess(caregiver, device).get()

        when:
        caregiverService.transferPrimaryUser(device.id, caregiverAccess.id, patient)

        then: "caregiver is now primary"
        deviceService.getUserAccess(caregiver, device).get().primaryUser

        and: "original patient is no longer primary"
        !deviceService.getUserAccess(patient, device).get().primaryUser
    }

    def "transferPrimaryUser should fail if requester is not primary user"() {
        given:
        def patient = userService.ensureExists("cg-xfer-2a")
        def caregiver1 = userService.ensureExists("cg-xfer-2b")
        def caregiver2 = userService.ensureExists("cg-xfer-2c")
        def record = deviceService.provision(patient, "cg-dev-xfer-2", "sn-xfer-2", "cl-xfer-2", "th-xfer-2")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver1, device)
        deviceService.addUserAccess(caregiver2, device)
        def caregiver1Access = deviceService.getUserAccess(caregiver1, device).get()

        when: "caregiver2 (non-primary) tries to transfer"
        caregiverService.transferPrimaryUser(device.id, caregiver1Access.id, caregiver2)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Only the current primary user can transfer primary status"
    }

    def "transferPrimaryUser should fail if requester has no access to device"() {
        given:
        def patient = userService.ensureExists("cg-xfer-3a")
        def stranger = userService.ensureExists("cg-xfer-3b")
        def caregiver = userService.ensureExists("cg-xfer-3c")
        def record = deviceService.provision(patient, "cg-dev-xfer-3", "sn-xfer-3", "cl-xfer-3", "th-xfer-3")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)
        def caregiverAccess = deviceService.getUserAccess(caregiver, device).get()

        when:
        caregiverService.transferPrimaryUser(device.id, caregiverAccess.id, stranger)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "No access to device"
    }

    def "transferPrimaryUser should fail if target deviceUserId does not exist"() {
        given:
        def patient = userService.ensureExists("cg-xfer-4")
        def record = deviceService.provision(patient, "cg-dev-xfer-4", "sn-xfer-4", "cl-xfer-4", "th-xfer-4")
        def device = record.logicalDevice
        def nonExistentId = UUID.randomUUID()

        when:
        caregiverService.transferPrimaryUser(device.id, nonExistentId, patient)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Target user not found"
    }

    def "transferPrimaryUser should fail if target belongs to a different device"() {
        given:
        def patient = userService.ensureExists("cg-xfer-5a")
        def caregiver = userService.ensureExists("cg-xfer-5b")
        def record1 = deviceService.provision(patient, "cg-dev-xfer-5a", "sn-xfer-5a", "cl-xfer-5a", "th-xfer-5a")
        def device1 = record1.logicalDevice
        def record2 = deviceService.provision(patient, "cg-dev-xfer-5b", "sn-xfer-5b", "cl-xfer-5b", "th-xfer-5b")
        def device2 = record2.logicalDevice
        deviceService.addUserAccess(caregiver, device2)
        def caregiverOnDevice2 = deviceService.getUserAccess(caregiver, device2).get()

        when: "patient tries to transfer device1's primary user to caregiver who is only on device2"
        caregiverService.transferPrimaryUser(device1.id, caregiverOnDevice2.id, patient)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Target user does not belong to this device"
    }
}
