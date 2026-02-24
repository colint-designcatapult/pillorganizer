package jct.pillorganizer.global.controller

import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import io.micronaut.test.support.TestPropertyProvider
import jakarta.inject.Inject
import jct.pillorganizer.core.dto.DeviceAccessDto
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.dto.UserAndDeviceAccessDto
import jct.pillorganizer.global.service.UserDeviceAccessService
import reactor.core.publisher.Flux
import spock.lang.Specification

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
        return ["micronaut.security.enabled": "false"]
    }

    void "test getUserDeviceAccess returns aggregated results"() {
        given:
        def device1 = new DeviceAccessDto("d1", "nickname1", "model1", "tenant1", "apiBase1", true)
        
        when:
        def request = HttpRequest.GET("/user/devices")
        def response = client.toBlocking().retrieve(request, UserAndDeviceAccessDto)

        then:
        1 * userDeviceAccessService.getUserDeviceAccess() >> Flux.just(device1)
        response.devices().size() == 1
        response.devices().get(0).id() == "d1"
    }
}
