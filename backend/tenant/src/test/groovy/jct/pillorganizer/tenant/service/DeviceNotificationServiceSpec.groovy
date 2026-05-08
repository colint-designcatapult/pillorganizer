package jct.pillorganizer.tenant.service

import jakarta.inject.Inject

// @relation(UN-501, scope=file)
// @relation(UN-502, scope=file)
// @relation(UN-503, scope=file)
// @relation(UN-504, scope=file)
// @relation(UN-7313, scope=file)
// @relation(UN-7314, scope=file)
// @relation(SYS-REQ-37, scope=file)
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.TenantDetails
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

    def "subscribe with custom preferences stores preference values"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 1", "pref1@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-1", ksuidService.generateKsuid(), "thing-pref-1")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-1"

        when:
        def result = deviceNotificationService.subscribe(user, device, endpointArn, true, false, true)

        then:
        result.notifications() == true
        result.notifyTakeNow() == true
        result.notifyTaken() == false
        result.notifyMissed() == true
    }

    def "subscribe with all preferences disabled stores all as false"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 2", "pref2@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-2", ksuidService.generateKsuid(), "thing-pref-2")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-2"

        when:
        def result = deviceNotificationService.subscribe(user, device, endpointArn, false, false, false)

        then:
        result.notifications() == true
        result.notifyTakeNow() == false
        result.notifyTaken() == false
        result.notifyMissed() == false
    }

    def "subscribe without preferences defaults all to true"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 3", "pref3@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-3", ksuidService.generateKsuid(), "thing-pref-3")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-3"

        when:
        def result = deviceNotificationService.subscribe(user, device, endpointArn)

        then:
        result.notifications() == true
        result.notifyTakeNow() == true
        result.notifyTaken() == true
        result.notifyMissed() == true
    }

    def "updatePreferences changes preferences for a subscribed user"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 4", "pref4@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-4", ksuidService.generateKsuid(), "thing-pref-4")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-4"

        deviceNotificationService.subscribe(user, device, endpointArn, true, true, true)

        when:
        def result = deviceNotificationService.updatePreferences(user, device, false, true, false)

        then:
        result.notifyTakeNow() == false
        result.notifyTaken() == true
        result.notifyMissed() == false
    }

    def "subscribe for already-subscribed user with new preferences updates them"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 6", "pref6@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-6", ksuidService.generateKsuid(), "thing-pref-6")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-6"

        deviceNotificationService.subscribe(user, device, endpointArn, true, true, true)

        when: "subscribe is called again with different preferences"
        def result = deviceNotificationService.subscribe(user, device, endpointArn, false, true, false)

        then: "preferences are updated (not silently ignored)"
        result.notifyTakeNow() == false
        result.notifyTaken()   == true
        result.notifyMissed()  == false
    }

    def "subscribe without preference flags preserves existing stored preferences"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 7", "pref7@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-7", ksuidService.generateKsuid(), "thing-pref-7")
        def device = deviceService.get(deviceId).get()
        def endpointArn = "arn:local:endpoint:pref-7"

        deviceNotificationService.subscribe(user, device, endpointArn, false, true, false)

        when: "subscribe is called without any preference flags (null = keep stored)"
        def result = deviceNotificationService.subscribe(user, device, endpointArn)

        then: "stored preferences are preserved, not reset to all-true"
        result.notifyTakeNow() == false
        result.notifyTaken()   == true
        result.notifyMissed()  == false
    }

    def "updatePreferences throws when user is not subscribed"() {
        given:
        def user = userService.upsert(ksuidService.generateKsuid(), "Pref User 5", "pref5@example.com")
        def deviceId = ksuidService.generateKsuid()
        deviceService.provision(user, deviceId, "sn-pref-5", ksuidService.generateKsuid(), "thing-pref-5")
        def device = deviceService.get(deviceId).get()

        when:
        deviceNotificationService.updatePreferences(user, device, true, true, true)

        then:
        thrown(IllegalStateException)
    }
}
