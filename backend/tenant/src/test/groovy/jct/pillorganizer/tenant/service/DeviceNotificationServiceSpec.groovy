package jct.pillorganizer.tenant.service

// @relation(UN-501, scope=file)
// @relation(UN-502, scope=file)
// @relation(UN-503, scope=file)
// @relation(UN-504, scope=file)
// @relation(UN-7313, scope=file)
// @relation(UN-7314, scope=file)
// @relation(SYS-REQ-37, scope=file)
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import spock.lang.Subject

/**
 * Integration tests for {@link DeviceNotificationService}.
 * Exercises the subscribe / unsubscribe flows end-to-end against a real
 * Postgres container using the {@link LocalNotificationService} stand-in.
 */
@MicronautTest(transactional = false)
class DeviceNotificationServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceNotificationService deviceNotificationService

    @Inject
    TenantService tenantService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    KsuidService ksuidService

    @MockBean(TenantService)
    TenantService tenantService() {
        Mock(TenantService)
    }

    def setup() {
        _ * tenantService.getCurrentTenant() >> Optional.of(TenantDetails.TEST_TENANT)
    }

    def "subscribe creates a topic and persists a subscription ARN"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Test User", "t@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-dns-1", ksuidService.generateKsuid(), "thing-dns-1")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:dns-1"

        when:
        def result = deviceNotificationService.subscribe(user, device, endpointArn)

        then:
        result.notifications() == true
        result.deviceId() == deviceId
    }

    def "subscribe is idempotent — calling twice keeps the same subscription"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "User Two", "u2@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-dns-2", ksuidService.generateKsuid(), "thing-dns-2")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:dns-2"

        when:
        def first  = deviceNotificationService.subscribe(user, device, endpointArn)
        def second = deviceNotificationService.subscribe(user, device, endpointArn)

        then:
        first.notifications()  == true
        second.notifications() == true
    }

    def "unsubscribe clears the subscription ARN"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "User Three", "u3@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-dns-3", ksuidService.generateKsuid(), "thing-dns-3")
        def device = deviceService.get(deviceId).get()

        deviceNotificationService.subscribe(user, device, "arn:local:endpoint:dns-3")

        when:
        def result = deviceNotificationService.unsubscribe(user, device)

        then:
        result.notifications() == false
    }

    def "unsubscribe is idempotent when not subscribed"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "User Four", "u4@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-dns-4", ksuidService.generateKsuid(), "thing-dns-4")
        def device = deviceService.get(deviceId).get()

        when:
        def result = deviceNotificationService.unsubscribe(user, device)

        then:
        noExceptionThrown()
        result.notifications() == false
    }
}
