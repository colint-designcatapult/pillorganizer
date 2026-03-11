package jct.pillorganizer.tenant.api.internal

import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.security.authentication.Authentication
import io.micronaut.security.utils.SecurityService
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.dto.DeviceAccessDto
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto
import jct.pillorganizer.core.dto.DeviceEligibilityCheckDto
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.user.User
import jct.pillorganizer.tenant.service.DeviceService
import jct.pillorganizer.tenant.service.UserService

@MicronautTest(transactional = false)
class InternalUserControllerSpec extends BaseIntegrationSpec {

    @Inject
    @Client("/")
    HttpClient client

    @Inject
    SecurityService securityService

    @Inject
    TenantService tenantService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    KsuidService ksuidService

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

    def setup() {
        _ * tenantService.getCurrentTenant() >> Optional.of(TenantDetails.TEST_TENANT)
    }

    def teardown() {

    }

    void "test getUserDevices returns devices for authenticated user"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-1", claimId, "thing-1")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/internal/user/devices")
        def response = client.toBlocking().retrieve(request, Argument.listOf(DeviceAccessDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)

        response.size() == 1
        with(response[0]) {
            // Required for app
            it.deviceId() == deviceId
            it.apiBase() != null
            it.tenantId() == TenantDetails.TEST_TENANT.id
            it.primaryUser()
        }
    }

    void "test getDevicePolicyDocument returns policy for authorized user"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)

        deviceService.provision(user, deviceId, "sn-2", claimId, "thing-2")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: user.id]

        when:
        def response = client.toBlocking().retrieve(
                HttpRequest.GET("/internal/user/device_access_policy?deviceId=" + deviceId),
                String
        )

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response != null
        response.contains("iot:Connect")
        response.contains("thing-2")
        response.contains(user.id)
    }

    void "test getDeviceClaimEligibility"() {
        given:
        String newDevId = ksuidService.generateKsuid()
        String existDevId = ksuidService.generateKsuid()
        
        User user3 = userService.ensureExists(ksuidService.generateKsuid())
        User otherUser = userService.ensureExists(ksuidService.generateKsuid())
        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: user3.id]

        when: "device doesn't exist"
        def check1 = new DeviceEligibilityCheckDto(newDevId, "sn-new")
        def resp1 = client.toBlocking().retrieve(
                HttpRequest.POST("/internal/user/device_claim_eligibility", check1),
                DeviceClaimEligibilityDto
        )

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        resp1.isEligible()
        !resp1.deviceExists()

        when: "device exists and user is primary"
        deviceService.create(user3, existDevId)

        def check2 = new DeviceEligibilityCheckDto(existDevId, "sn-existing")
        def resp2 = client.toBlocking().retrieve(
                HttpRequest.POST("/internal/user/device_claim_eligibility", check2),
                DeviceClaimEligibilityDto
        )

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        resp2.isEligible()
        resp2.deviceExists()

        when: "device exists but user is not primary"
        deviceService.create(otherUser, newDevId)

        def check3 = new DeviceEligibilityCheckDto(newDevId, "sn-other")
        def resp3 = client.toBlocking().retrieve(
                HttpRequest.POST("/internal/user/device_claim_eligibility", check3),
                DeviceClaimEligibilityDto
        )

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        !resp3.isEligible()
        resp3.deviceExists()
    }
}
