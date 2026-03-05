package jct.pillorganizer.global.controller

import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.dto.DeviceAccessDto
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.dto.UserAndDeviceAccessDto
import jct.pillorganizer.global.service.UserDeviceAccessService
import reactor.core.publisher.Flux

@MicronautTest
class UserDeviceAccessControllerSpec extends BaseIntegrationSpec {

    @Inject
    @Client("/")
    HttpClient client

    @Inject
    UserDeviceAccessService userDeviceAccessService

    @MockBean(UserDeviceAccessService)
    UserDeviceAccessService userDeviceAccessService() {
        Mock(UserDeviceAccessService)
    }

    @Override
    Map<String, String> getProperties() {
        return super.getProperties() + ["micronaut.security.enabled": "false"]
    }

    // @relation(CTRL-REQ-11, scope=range_start)
    // @relation(CTRL-REQ-15, scope=range_start)
    void "test getUserDeviceAccess returns aggregated results"() {
        given:
        def device1 = new DeviceAccessDto("d1", "dev1", "nickname1", "sn1", "model1", "tenant1", "apiBase1", true, "tenant1-sn1")
        def device2 = new DeviceAccessDto("d2", "dev2", "nickname2", "sn2", "model2", "tenant2", "apiBase2", false, "tenant2-sn2")
        
        when:
        def request = HttpRequest.GET("/user/devices")
        def response = client.toBlocking().retrieve(request, UserAndDeviceAccessDto)

        then:
        1 * userDeviceAccessService.getUserDeviceAccess() >> Flux.just(device1, device2)
        response.devices().size() == 2
        
        with(response.devices().find { it.deviceId() == "d1" }) {
            deviceId() == "d1"
            claimId() == "dev1"
            nickname() == "nickname1"
            serialNo() == "sn1"
            modelId() == "model1"
            tenantId() == "tenant1"
            apiBase() == "apiBase1"
            primaryUser() == true
        }

        with(response.devices().find { it.deviceId() == "d2" }) {
            deviceId() == "d2"
            claimId() == "dev2"
            nickname() == "nickname2"
            serialNo() == "sn2"
            modelId() == "model2"
            tenantId() == "tenant2"
            apiBase() == "apiBase2"
            primaryUser() == false
        }
    }
    // @relation(CTRL-REQ-15, scope=range_end)
    // @relation(CTRL-REQ-11, scope=range_end)
}
