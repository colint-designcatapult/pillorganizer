package jct.pillorganizer.tenant.api.app

import io.micronaut.http.HttpRequest
import io.micronaut.http.HttpStatus
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.http.client.exceptions.HttpClientResponseException
import io.micronaut.security.utils.SecurityService
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.tenant.BaseIntegrationSpec

import java.nio.charset.StandardCharsets

@MicronautTest(transactional = false)
class AppScheduleControllerSpec extends BaseIntegrationSpec {

    @Inject
    @Client("/")
    HttpClient client

    @Inject
    SecurityService securityService

    @Inject
    TenantService tenantService

    @MockBean(SecurityService)
    SecurityService securityService() {
        Mock(SecurityService)
    }

    @MockBean(TenantService)
    TenantService tenantService() {
        Mock(TenantService)
    }

    @Override
    Map<String, String> getProperties() {
        return super.getProperties() + [
                "micronaut.security.enabled": "false"
        ]
    }

    void "GET /default-schedule returns 200 with decoded schedule when tenant has default configured"() {
        given:
        def scheduleJson = '{"type":"SIMPLE","bins":[{"dayOfWeek":"MONDAY","time":"08:00"},{"dayOfWeek":"MONDAY","time":"20:00"}]}'
        def encoded = Base64.getEncoder().encodeToString(scheduleJson.getBytes(StandardCharsets.UTF_8))
        def tenant = new TenantDetails("test-tenant", true, "localhost", "http://localhost", "Test", encoded)
        tenantService.getCurrentTenant() >> Optional.of(tenant)
        securityService.getAuthentication() >> Optional.empty()

        when:
        def request = HttpRequest.GET("/api/v1/device/default-schedule")
        def response = client.toBlocking().retrieve(request, Map)

        then:
        response.type == "SIMPLE"
        response.bins.size() == 2
        response.bins[0].dayOfWeek == "MONDAY"
        response.bins[0].time == "08:00"
        response.bins[1].dayOfWeek == "MONDAY"
        response.bins[1].time == "20:00"
    }

    void "GET /default-schedule returns 404 when tenant has no default schedule configured"() {
        given:
        def tenant = new TenantDetails("test-tenant", true, "localhost", "http://localhost", "Test", null)
        tenantService.getCurrentTenant() >> Optional.of(tenant)
        securityService.getAuthentication() >> Optional.empty()

        when:
        def request = HttpRequest.GET("/api/v1/device/default-schedule")
        client.toBlocking().retrieve(request, Map)

        then:
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "GET /default-schedule returns 404 when default schedule is blank"() {
        given:
        def tenant = new TenantDetails("test-tenant", true, "localhost", "http://localhost", "Test", "   ")
        tenantService.getCurrentTenant() >> Optional.of(tenant)
        securityService.getAuthentication() >> Optional.empty()

        when:
        def request = HttpRequest.GET("/api/v1/device/default-schedule")
        client.toBlocking().retrieve(request, Map)

        then:
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "GET /default-schedule returns 404 when default schedule is invalid base64"() {
        given:
        def tenant = new TenantDetails("test-tenant", true, "localhost", "http://localhost", "Test", "not-valid-base64!!!")
        tenantService.getCurrentTenant() >> Optional.of(tenant)
        securityService.getAuthentication() >> Optional.empty()

        when:
        def request = HttpRequest.GET("/api/v1/device/default-schedule")
        client.toBlocking().retrieve(request, Map)

        then:
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "GET /default-schedule returns 404 when no current tenant is resolved"() {
        given:
        tenantService.getCurrentTenant() >> Optional.empty()
        securityService.getAuthentication() >> Optional.empty()

        when:
        def request = HttpRequest.GET("/api/v1/device/default-schedule")
        client.toBlocking().retrieve(request, Map)

        then:
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }
}
