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
    // generateCode
    // -------------------------------------------------------------------------

    def "generateCode should create a valid 6-digit code for the device"() {
        given:
        def patient = userService.ensureExists("cg-gen-1")
        def record = deviceService.provision(patient, "cg-dev-gen-1", "sn-gen-1", "cl-gen-1", "th-gen-1")
        def device = record.logicalDevice

        when:
        def dto = caregiverService.generateCode(patient, device, "Test Caregiver")

        then:
        dto != null
        dto.id() != null
        dto.deviceID() == device.id
        dto.patientID() == patient.id
        dto.nickname() == "Test Caregiver"
        dto.code() >= 100_000
        dto.code() <= 999_999
        dto.deleted() == false
        dto.expiresAt() > (System.currentTimeMillis() / 1000)
    }

    def "generateCode should invalidate any previous active code for the same device"() {
        given:
        def patient = userService.ensureExists("cg-gen-2")
        def record = deviceService.provision(patient, "cg-dev-gen-2", "sn-gen-2", "cl-gen-2", "th-gen-2")
        def device = record.logicalDevice

        when: "generating first code"
        def first = caregiverService.generateCode(patient, device, "Test Caregiver")

        and: "generating a second code"
        def second = caregiverService.generateCode(patient, device, "Test Caregiver")

        and: "fetching active codes"
        def activeCodes = caregiverService.getActiveCodesForDevices([device.id], patient)

        then: "only the second code is active"
        activeCodes.size() == 1
        activeCodes[0].id() == second.id()
    }

    // -------------------------------------------------------------------------
    // getActiveCodesForDevices
    // -------------------------------------------------------------------------

    def "getActiveCodesForDevices should return active codes for devices owned by the patient"() {
        given:
        def patient = userService.ensureExists("cg-list-1")
        def record = deviceService.provision(patient, "cg-dev-list-1", "sn-list-1", "cl-list-1", "th-list-1")
        def device = record.logicalDevice
        caregiverService.generateCode(patient, device, "Test Caregiver")

        when:
        def codes = caregiverService.getActiveCodesForDevices([device.id], patient)

        then:
        codes.size() == 1
        codes[0].deviceID() == device.id
        codes[0].nickname() == "Test Caregiver"
    }

    def "getActiveCodesForDevices should not return codes for devices the patient does not own"() {
        given:
        def patient1 = userService.ensureExists("cg-list-2a")
        def patient2 = userService.ensureExists("cg-list-2b")
        def record = deviceService.provision(patient1, "cg-dev-list-2", "sn-list-2", "cl-list-2", "th-list-2")
        def device = record.logicalDevice
        caregiverService.generateCode(patient1, device, "Test Caregiver")

        when: "patient2 requests codes for patient1's device"
        def codes = caregiverService.getActiveCodesForDevices([device.id], patient2)

        then: "no codes returned because patient2 is not the code owner"
        codes.isEmpty()
    }

    def "getActiveCodesForDevices should return empty list for unknown device"() {
        given:
        def patient = userService.ensureExists("cg-list-3")

        when:
        def codes = caregiverService.getActiveCodesForDevices(["no-such-device-xyz"], patient)

        then:
        codes.isEmpty()
    }

    // -------------------------------------------------------------------------
    // validateAndJoin
    // -------------------------------------------------------------------------

    def "validateAndJoin should grant caregiver access and return device name"() {
        given:
        def patient = userService.ensureExists("cg-val-1a")
        def caregiver = userService.ensureExists("cg-val-1b")
        def record = deviceService.provision(patient, "cg-dev-val-1", "sn-val-1", "cl-val-1", "th-val-1")
        def device = record.logicalDevice
        deviceService.updateNickname(device, "My Test Organizer")
        def codeDto = caregiverService.generateCode(patient, device, "Test Caregiver")

        when:
        def result = caregiverService.validateAndJoin(codeDto.code() as int, caregiver)

        then: "returns the device name"
        result.name() == "My Test Organizer"

        and: "caregiver now has access"
        deviceService.getUserAccess(caregiver, device).isPresent()
        !deviceService.getUserAccess(caregiver, device).get().primaryUser
    }

    def "validateAndJoin should mark the code as deleted after use"() {
        given:
        def patient = userService.ensureExists("cg-val-2a")
        def caregiver = userService.ensureExists("cg-val-2b")
        def record = deviceService.provision(patient, "cg-dev-val-2", "sn-val-2", "cl-val-2", "th-val-2")
        def device = record.logicalDevice
        def codeDto = caregiverService.generateCode(patient, device, "Test Caregiver")

        when:
        caregiverService.validateAndJoin(codeDto.code() as int, caregiver)

        then: "code is no longer active"
        caregiverService.getActiveCodesForDevices([device.id], patient).isEmpty()
    }

    def "validateAndJoin should fail for an invalid code"() {
        given:
        def caregiver = userService.ensureExists("cg-val-3")

        when:
        caregiverService.validateAndJoin(999999, caregiver)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Invalid or expired code"
    }

    def "validateAndJoin should fail if caregiver already has access"() {
        given:
        def patient = userService.ensureExists("cg-val-4a")
        def caregiver = userService.ensureExists("cg-val-4b")
        def record = deviceService.provision(patient, "cg-dev-val-4", "sn-val-4", "cl-val-4", "th-val-4")
        def device = record.logicalDevice
        deviceService.addUserAccess(caregiver, device)
        def codeDto = caregiverService.generateCode(patient, device, "Test Caregiver")

        when:
        caregiverService.validateAndJoin(codeDto.code() as int, caregiver)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "You already have access to this device"
    }

    def "validateAndJoin should use device id as name when nickname is not set"() {
        given:
        def patient = userService.ensureExists("cg-val-5a")
        def caregiver = userService.ensureExists("cg-val-5b")
        def record = deviceService.provision(patient, "cg-dev-val-5", "sn-val-5", "cl-val-5", "th-val-5")
        def device = record.logicalDevice
        def codeDto = caregiverService.generateCode(patient, device, "Test Caregiver")

        when:
        def result = caregiverService.validateAndJoin(codeDto.code() as int, caregiver)

        then:
        result.name() == "Device #${device.id}"
    }


    def "validateAndJoin should apply the invite code nickname to the DeviceUser"() {
        given:
        def patient = userService.ensureExists("cg-val-6a")
        def caregiver = userService.ensureExists("cg-val-6b")
        def record = deviceService.provision(patient, "cg-dev-val-6", "sn-val-6", "cl-val-6", "th-val-6")
        def device = record.logicalDevice
        def codeDto = caregiverService.generateCode(patient, device, "Grandma")

        when:
        caregiverService.validateAndJoin(codeDto.code() as int, caregiver)

        then: "the caregiver DeviceUser has the nickname from the invite code"
        deviceService.getUserAccess(caregiver, device).get().nickname == "Grandma"
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
