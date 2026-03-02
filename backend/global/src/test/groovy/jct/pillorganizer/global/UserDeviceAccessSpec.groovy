package jct.pillorganizer.global

import io.micronaut.http.client.exceptions.HttpClientException
import jct.pillorganizer.core.dto.DeviceAccessDto
import jct.pillorganizer.global.client.TenantClient
import jct.pillorganizer.global.service.UserDeviceAccessService
import reactor.core.publisher.Mono

class UserDeviceAccessSpec extends BaseIntegrationSpec {

    // @relation(CTRL-REQ-13, scope=range_start)
    void "test getUserDeviceAccess aggregates results from tenants"() {
        given:
        def tenant1 = Mock(TenantClient)
        def tenant2 = Mock(TenantClient)
        def service = new UserDeviceAccessService(tenants: [tenant1, tenant2])
        
        def device1 = new DeviceAccessDto("d1", "dev1", "nickname1", "sn1", "model1", "tenant1", "apiBase1", true)
        def device2 = new DeviceAccessDto("d2", "dev2", "nickname2", "sn2", "model2", "tenant2", "apiBase2", false)

        when:
        def result = service.getUserDeviceAccess().collectList().block()

        then:
        1 * tenant1.getDeviceAccess() >> Mono.just([device1])
        1 * tenant2.getDeviceAccess() >> Mono.just([device2])
        result.size() == 2
        result.contains(device1)
        result.contains(device2)
    }

    void "test getUserDeviceAccess handles errors gracefully"() {
        given:
        def tenant1 = Mock(TenantClient)
        def tenant2 = Mock(TenantClient)
        def service = new UserDeviceAccessService(tenants: [tenant1, tenant2])
        
        def device1 = new DeviceAccessDto("d1", "dev1", "nickname1", "sn1", "model1", "tenant1", "apiBase1", true)

        when:
        def result = service.getUserDeviceAccess().collectList().block()

        then:
        1 * tenant1.getDeviceAccess() >> Mono.just([device1])
        1 * tenant2.getDeviceAccess() >> Mono.error(new HttpClientException("Error"))
        result.size() == 1
        result.contains(device1)
    }
    // @relation(CTRL-REQ-13, scope=range_end)
}
