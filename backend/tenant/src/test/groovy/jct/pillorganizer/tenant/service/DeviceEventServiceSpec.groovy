package jct.pillorganizer.tenant.service

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.IotDeviceEventMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.repo.DeviceEventRepository
import spock.lang.Subject

@MicronautTest
class DeviceEventServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceEventService deviceEventService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    DeviceEventRepository deviceEventRepository

    def "should save a device event and convert timestamp to instant"() {
        given:
        def user = userService.upsert("des-user-1", "User One", "user1@example.com")
        deviceService.provision(user, "des-device-1", "des-serial-1", "des-claim-1", "des-thing-1")

        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-1")
                .tenant("des-tenant")
                .timestamp(1_700_000_000_000L)
                .eventType("DOOR_OPENED")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        def events = deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-device-1" && it.eventType == "DOOR_OPENED"
        }
        events.size() == 1
        events[0].id != null
        events[0].timestamp == java.time.Instant.ofEpochMilli(1_700_000_000_000L)
        events[0].binId == null
        events[0].metadata == null
        events[0].scheduleId == null
    }

    def "should save a device event with all optional fields"() {
        given:
        def user = userService.upsert("des-user-2", "User Two", "user2@example.com")
        deviceService.provision(user, "des-device-2", "des-serial-2", "des-claim-2", "des-thing-2")

        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-2")
                .tenant("des-tenant")
                .timestamp(1_700_000_002_000L)
                .eventType("TAKEN")
                .binId(3)
                .flags(1)
                .scheduleId("sched-abc")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        def events = deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-device-2" && it.eventType == "TAKEN"
        }
        events.size() == 1
        events[0].timestamp == java.time.Instant.ofEpochMilli(1_700_000_002_000L)
        events[0].binId == 3
        events[0].metadata == '{"flags":1}'
        events[0].scheduleId == "sched-abc"
    }

    def "should silently drop a duplicate event (same thingName, timestamp, eventType, binId)"() {
        given:
        def user = userService.upsert("des-user-3", "User Three", "user3@example.com")
        deviceService.provision(user, "des-device-3", "des-serial-3", "des-claim-3", "des-thing-3")

        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-3")
                .tenant("des-tenant")
                .timestamp(1_700_000_003_000L)
                .eventType("DOOR_CLOSED")
                .binId(1)
                .build()

        when: "the same message is processed twice"
        deviceEventService.processEvent(message)
        deviceEventService.processEvent(message)

        then: "no exception is thrown and only one row exists"
        noExceptionThrown()
        deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-device-3" && it.eventType == "DOOR_CLOSED"
        }.size() == 1
    }

    def "should treat events with different bin ids as distinct"() {
        given:
        def user = userService.upsert("des-user-4", "User Four", "user4@example.com")
        deviceService.provision(user, "des-device-4", "des-serial-4", "des-claim-4", "des-thing-4")

        def ts = 1_700_000_004_000L

        when:
        deviceEventService.processEvent(IotDeviceEventMessage.builder()
                .thingName("des-thing-4").tenant("t").timestamp(ts).eventType("TAKEN").binId(1).build())
        deviceEventService.processEvent(IotDeviceEventMessage.builder()
                .thingName("des-thing-4").tenant("t").timestamp(ts).eventType("TAKEN").binId(2).build())

        then:
        deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-device-4" && it.eventType == "TAKEN"
        }.size() == 2
    }

    def "should throw when no logical device exists for the given thingName"() {
        given:
        def message = IotDeviceEventMessage.builder()
                .thingName("unknown-thing")
                .tenant("des-tenant")
                .timestamp(1_700_000_005_000L)
                .eventType("DOOR_OPENED")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        def e = thrown(IllegalStateException)
        e.message.contains("unknown-thing")
    }
}
