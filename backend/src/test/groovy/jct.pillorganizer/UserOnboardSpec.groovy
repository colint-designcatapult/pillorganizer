package jct.pillorganizer

import com.google.protobuf.ByteString
import io.micronaut.http.client.exceptions.HttpClientResponseException
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.dto.SaveMedicationDTO
import jct.pillorganizer.dto.SimpleScheduleDTO
import jct.pillorganizer.dto.UpdateDeviceUserSettings
import jct.pillorganizer.dto.VerifyProvision
import jct.pillorganizer.model.device.DeviceClass
import jct.pillorganizer.model.medication.MedicationShape
import jct.pillorganizer.proto.Pill
import jct.pillorganizer.service.FirmwareService
import spock.lang.Ignore
import spock.lang.Specification
import spock.lang.Stepwise
import spock.lang.IgnoreIf
import spock.lang.Requires

@MicronautTest()
@Stepwise
class UserOnboardSpec extends Specification {

    @Inject
    ApiV1Client client

    @Inject
    DeviceApiClient deviceApiClient

    @Inject
    ApiJWTFilter filter

    @Inject
    DeviceJWTFilter deviceJWTFilter

    @Inject
    FirmwareService firmwareService

    void deviceLogin(long sn, String oobKey) {
        Pill.AuthorizeRequest authorizeRequest = Pill.AuthorizeRequest.newBuilder()
                .setSerialNo(sn)
                .setOobKey(ByteString.fromHex(oobKey))
                .build()
        Pill.AuthorizeResponse resp = Pill.AuthorizeResponse.parseFrom(deviceApiClient.loginDevice(authorizeRequest.toByteArray()))
        deviceJWTFilter.setCreds(resp.getAccessToken())
    }

    def checkProvisioning(long provID, long sn, String ssid) {
        VerifyProvision vp = new VerifyProvision()
        vp.setSerialNo(sn)
        vp.setSsid(ssid)
        return client.checkProvisionStatus(provID, vp)
    }

    Pill.SyncResponse completeProvisioning(String bssid, String ssid) {
        Pill.DeviceProvisionRequest req = Pill.DeviceProvisionRequest.newBuilder()
                .setBssid(ByteString.fromHex(bssid))
                .setSsid(ssid)
                .build()

        byte[] res = deviceApiClient.completeProvisioning(req.toByteArray())
        Pill.SyncResponse.parseFrom(res)
    }

    void loginAnonymous() {
        var res = client.registerAnonymous()
        filter.setCreds(client.loginAnonymous(res.id, res.secret))
    }

    def registerAndLogin(String email, String password) {
        var res = client.register(email, password)
        filter.setCreds(client.login(email, password))
        res
    }

    final email = "test@test.com"
    final password = "abcd1234"

    final bssid_1 = "aabbccdd1122"
    final ssid_1 = "TEST WiFi 123"
    final serial_1 = Long.parseLong("3412fecaefbe", 16)

    final bssid_2 = "beefcafebabe"
    final ssid_2 = "Wifi_Network"
    final serial_2 = Long.parseLong("4151996fc6d5", 16)


    @Ignore
    void "anonymous provision start"() {
        when:
        loginAnonymous()

        var prov = client.provisionStart(Long.toHexString(serial_1), "v1_7x2")
        deviceLogin(serial_1, prov.oobKey)
        checkProvisioning(prov.id, serial_1, ssid_1)

        then:
        def e = thrown HttpClientResponseException
        e.message.contains("Bad Request")
        prov.id == 1
        prov.oobKey.length() == 32
    }

    @Ignore
    void "anonymous provision complete"() {
        when:
        var syncResp = completeProvisioning(bssid_1, ssid_1)
        var check = checkProvisioning(1, serial_1, ssid_1)

        then:
        check.deviceID == 1
        check.provisioned == true
        syncResp.getLatestFirmware() == firmwareService.latestVersion
        syncResp.getBinState().getBinsCount() == 14
        syncResp.getScheduleCount() == 14
    }

    @Ignore
    void "user provision start"() {
        when:
        filter.setCreds(null)
        deviceJWTFilter.setCreds(null)

        registerAndLogin(email, password)

        var prov = client.provisionStart(Long.toHexString(serial_2), "v1_7x2")
        deviceLogin(serial_2, prov.oobKey)
        checkProvisioning(prov.id, serial_2, ssid_2)

        then:
        def e = thrown HttpClientResponseException
        e.message.contains("Bad Request")
        prov.id == 2
        prov.userID == 2
        prov.oobKey.length() == 32
    }

    // todo: check security on this endpoint
    /*void "user provision already provisioned"() {
        when:
        var c = checkProvisioning(1, serial_1, ssid_1)
        println(c)

        then:
        thrown HttpClientResponseException
    }*/
    @Ignore
    void "user provision complete"() {
        when:
        var syncResp = completeProvisioning(bssid_2, ssid_2)
        var check = checkProvisioning(2, serial_2, ssid_2)

        then:
        check.deviceID == 2
        check.provisioned == true
        syncResp.getLatestFirmware() == firmwareService.latestVersion
        syncResp.getBinState().getBinsCount() == 14
        syncResp.getScheduleCount() == 14
    }

    @Ignore
    void "user device shows in device list"() {
        when:
        var list = client.listDevices()
        var first = list.first()

        then:
        list.size() == 1
        first.id() == 2
        first.deviceID() == 2
        first.deviceClass() == DeviceClass.v1_7x2
        first.owner()
        !first.notifications()
    }

    @Ignore
    void "user set device settings"() {
        when:
        client.deviceSettings(2, new UpdateDeviceUserSettings(
                Optional.of("Test Device"),
                Optional.of("abcd1234"),
                Optional.of(true),
                Optional.of("America/Los_Angeles"))
        )

        var byID = client.listDevices().first()

        then:
        byID.timezone() == "America/Los_Angeles"
        byID.notifications()
        byID.customName() == "Test Device"
    }

    @Ignore
    void "user set device settings on non owned"() {
        when:
        client.deviceSettings(1, new UpdateDeviceUserSettings(Optional.of("Test Device"), Optional.empty(),
                Optional.empty(), Optional.empty()))

        then:
        thrown HttpClientResponseException
    }

    @Ignore
    void "user get schedule"() {
        when:
        var dispenseTime = client.getDispenseTime(2)

        then:
        dispenseTime.amID() == null
        dispenseTime.amSecondsFrom00() == null
        dispenseTime.pmID() == null
        dispenseTime.pmSecondsFrom00() == null
    }

    @Ignore
    void "user set am"() {
        when:
        var dispenseTime = client.setDispenseTime(2, new SimpleScheduleDTO(null, 100, null, null))
        var dt = client.getDispenseTime(2)

        then:
        dispenseTime == dt
        dispenseTime.amID() != null
        dispenseTime.amSecondsFrom00() == 100
        dispenseTime.pmID() == null
        dispenseTime.pmSecondsFrom00() == null
    }

    @Ignore
    void "user set pm"() {
        when:
        var dt = client.getDispenseTime(2)
        var res = client.setDispenseTime(2, new SimpleScheduleDTO(dt.amID(), dt.amSecondsFrom00(),
                null, 1800))

        then:
        res.amID() == 1
        res.amSecondsFrom00() == 100
        res.pmID() == 2
        res.pmSecondsFrom00() == 1800
    }

    @Ignore
    void "user create medication"() {
        when:
        var dt = client.getDispenseTime(2)

        var dto = new SaveMedicationDTO(
                null, "Test Med", MedicationShape.CAPSULE, 3314600, Set.of(dt.pmID())
        )

        var res = client.saveMedication(2, dto)
        var fd = res.getDispenseTimes().first()

        then:
        res.getMed_name() == "Test Med"
        res.getShape() == MedicationShape.CAPSULE
        res.getColor() == 3314600
        res.getDeviceID() == 2
        res.getId() == 1
        res.getDispenseTimes().size() == 1
        fd.dispenseID == 2
        fd.medicationID == res.getId()
    }

    @Ignore
    void "user update medication all times"() {
        when:
        var dt = client.getDispenseTime(2)

        var dto = new SaveMedicationDTO(
                1, "Test Med 2", MedicationShape.OCTAGON, 3314600, Set.of(dt.pmID(), dt.amID())
        )

        var res = client.saveMedication(2, dto)
        var sorted = res.getDispenseTimes().sort {it.id}

        then:
        res.getMed_name() == "Test Med 2"
        res.getShape() == MedicationShape.OCTAGON
        res.getColor() == 3314600
        res.getDeviceID() == 2
        res.getId() == 1
        res.getDispenseTimes().size() == 2
        sorted.first().dispenseID == 2
        sorted.first().medicationID == res.getId()
        sorted.last().dispenseID == 1
        sorted.last().medicationID == res.getId()
    }

    @Ignore
    void "user update medication remove pm"() {
        when:
        var dt = client.getDispenseTime(2)

        var dto = new SaveMedicationDTO(
                1, "Test Med 3", MedicationShape.OCTAGON, 3314601, Set.of(dt.amID())
        )

        var res = client.saveMedication(2, dto)
        var fd = res.getDispenseTimes().first()

        then:
        res.getMed_name() == "Test Med 3"
        res.getShape() == MedicationShape.OCTAGON
        res.getColor() == 3314601
        res.getDeviceID() == 2
        res.getId() == 1
        res.getDispenseTimes().size() == 1
        fd.dispenseID == 1
        fd.medicationID == res.getId()
    }

}