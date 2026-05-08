package jct.pillorganizer.tenant.service

// @relation(UN-404, scope=file)
// @relation(UN-503, scope=file)
// @relation(UN-504, scope=file)
// @relation(UN-401, scope=file)
// @relation(UN-405, scope=file)
// @relation(UN-406, scope=file)
// @relation(UN-407, scope=file)
// @relation(UN-408, scope=file)
// @relation(SYS-REQ-13, scope=file)
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.IotDeviceEventMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.repo.DeviceEventRepository
import jct.pillorganizer.tenant.repo.LogicalDeviceRepository
import spock.lang.Subject

import java.time.Instant

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

    @Inject
    LogicalDeviceRepository logicalDeviceRepository

    @Inject
    NotificationService notificationService

    @MockBean(NotificationService)
    NotificationService notificationService() {
        Mock(NotificationService)
    }

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
        def epochWeek = 1_700_000_640L
        def scheduledTime = 1_700_001_200L

        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-2")
                .tenant("des-tenant")
                .timestamp(1_700_000_002_000L)
                .eventType("TAKEN")
                .binId(3)
                .flags(1)
                .scheduleId("sched-abc")
                .epochWeek(epochWeek)
                .scheduledTime(scheduledTime)
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
        events[0].epochWeek == Instant.ofEpochSecond(epochWeek)
        events[0].scheduledTime == Instant.ofEpochSecond(scheduledTime)
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

    def "should publish a notification when event type is TAKEN and device has a topic"() {
        given:
        def user = userService.upsert("des-user-notif-1", "Notif User", "notif1@example.com")
        deviceService.provision(user, "des-notif-device-1", "des-sn-n1", "des-claim-n1", "des-thing-n1")

        def topicArn = "arn:local:sns:local:000000000000:device-des-notif-device-1"
        logicalDeviceRepository.updateTopicArn("des-notif-device-1", topicArn)

        // Use a recent timestamp (1 minute ago) so TTL is still positive
        def recentTimestamp = Instant.now().minusSeconds(60).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n1")
                .tenant("des-tenant")
                .timestamp(recentTimestamp)
                .eventType("TAKEN")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        1 * notificationService.publish(topicArn, "CabiNET", "Your dose was recorded as taken.", { it > 0 && it <= 900 }, "TAKEN")
        deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-notif-device-1" && it.eventType == "TAKEN"
        }.size() == 1
    }

    def "should publish a notification when event type is MISSED and device has a topic"() {
        given:
        def user = userService.upsert("des-user-notif-2", "Notif User 2", "notif2@example.com")
        deviceService.provision(user, "des-notif-device-2", "des-sn-n2", "des-claim-n2", "des-thing-n2")

        def topicArn = "arn:local:sns:local:000000000000:device-des-notif-device-2"
        logicalDeviceRepository.updateTopicArn("des-notif-device-2", topicArn)

        // Use a recent timestamp (1 minute ago) so TTL is still positive
        def recentTimestamp = Instant.now().minusSeconds(60).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n2")
                .tenant("des-tenant")
                .timestamp(recentTimestamp)
                .binId(8)
                .eventType("MISSED")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        1 * notificationService.publish(topicArn, "CabiNET", "Reminder: no activity detected for the Friday PM dose.", { it > 0 && it <= 900 }, "MISSED")
        deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-notif-device-2" && it.eventType == "MISSED"
        }.size() == 1
    }

    def "should not publish a notification when event type is TAKEN but device has no topic"() {
        given:
        def user = userService.upsert("des-user-notif-3", "Notif User 3", "notif3@example.com")
        deviceService.provision(user, "des-notif-device-3", "des-sn-n3", "des-claim-n3", "des-thing-n3")

        def recentTimestamp = Instant.now().minusSeconds(60).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n3")
                .tenant("des-tenant")
                .timestamp(recentTimestamp)
                .eventType("TAKEN")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        0 * notificationService.publish(_, _, _, _, _)
        noExceptionThrown()
    }

    def "should not publish a notification when the event timestamp is more than 15 minutes ago"() {
        given:
        def user = userService.upsert("des-user-notif-4", "Notif User 4", "notif4@example.com")
        deviceService.provision(user, "des-notif-device-4", "des-sn-n4", "des-claim-n4", "des-thing-n4")

        def topicArn = "arn:local:sns:local:000000000000:device-des-notif-device-4"
        logicalDeviceRepository.updateTopicArn("des-notif-device-4", topicArn)

        // Event is 20 minutes old — TTL would be 900 - 1200 = -300 → skip
        def expiredTimestamp = Instant.now().minusSeconds(20 * 60).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n4")
                .tenant("des-tenant")
                .timestamp(expiredTimestamp)
                .binId(5)
                .eventType("TAKEN")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        0 * notificationService.publish(_, _, _, _, _)
        noExceptionThrown()
        // Event is still persisted even if notification is skipped
        deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "des-notif-device-4" && it.eventType == "TAKEN"
        }.size() == 1
    }

    def "should not publish a notification when the event timestamp is exactly 15 minutes ago"() {
        given:
        def user = userService.upsert("des-user-notif-5", "Notif User 5", "notif5@example.com")
        deviceService.provision(user, "des-notif-device-5", "des-sn-n5", "des-claim-n5", "des-thing-n5")

        def topicArn = "arn:local:sns:local:000000000000:device-des-notif-device-5"
        logicalDeviceRepository.updateTopicArn("des-notif-device-5", topicArn)

        // Event is exactly 15 minutes + 1 second old — TTL = 900 - 901 = -1 → skip
        def borderTimestamp = Instant.now().minusSeconds(15 * 60 + 1).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n5")
                .tenant("des-tenant")
                .timestamp(borderTimestamp)
                .binId(4)
                .eventType("MISSED")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        0 * notificationService.publish(_, _, _, _, _)
        noExceptionThrown()
    }

    def "should compute correct TTL based on event age"() {
        given:
        def user = userService.upsert("des-user-notif-6", "Notif User 6", "notif6@example.com")
        deviceService.provision(user, "des-notif-device-6", "des-sn-n6", "des-claim-n6", "des-thing-n6")

        def topicArn = "arn:local:sns:local:000000000000:device-des-notif-device-6"
        logicalDeviceRepository.updateTopicArn("des-notif-device-6", topicArn)

        // Event is 5 minutes old → expected TTL = 900 - 300 = ~600s (within ±5s tolerance for test execution)
        def fiveMinutesAgo = Instant.now().minusSeconds(5 * 60).toEpochMilli()
        def message = IotDeviceEventMessage.builder()
                .thingName("des-thing-n6")
                .tenant("des-tenant")
                .timestamp(fiveMinutesAgo)
                .binId(10)
                .eventType("TAKEN")
                .build()

        when:
        deviceEventService.processEvent(message)

        then:
        1 * notificationService.publish(topicArn, "CabiNET", "Your Saturday PM dose was recorded as taken.",
                { long ttl -> ttl >= 595 && ttl <= 605 }, "TAKEN")
    }
}
