package jct.pillorganizer.tenant.service

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.device.Device
import spock.lang.Subject

@MicronautTest
class DeviceServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceService deviceService

    def "create should persist a new device"() {
        given:
        String deviceId = "device123"
        String serialNo = "SN123456"
        String claimToken = "token-abc"

        when:
        Device result = deviceService.create(deviceId, serialNo, claimToken)

        then:
        result != null
        result.id == deviceId
        result.serialNo == serialNo
        result.claimToken == claimToken
    }

    def "findById should return existing device"() {
        given:
        String deviceId = "device456"
        String serialNo = "SN654321"
        String claimToken = "token-xyz"
        deviceService.create(deviceId, serialNo, claimToken)

        when:
        Device result = deviceService.findById(deviceId)

        then:
        result != null
        result.id == deviceId
        result.serialNo == serialNo
        result.claimToken == claimToken
    }

    def "findById should throw exception for non-existent device"() {
        given:
        String deviceId = "nonExistentDevice"

        when:
        deviceService.findById(deviceId)

        then:
        thrown(IllegalArgumentException)
    }
}
