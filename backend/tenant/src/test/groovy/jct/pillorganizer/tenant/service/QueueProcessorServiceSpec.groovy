package jct.pillorganizer.tenant.service

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-8, scope=file)
// @relation(CTRL-REQ-25, scope=file)
// @relation(UN-301, scope=file)
// @relation(UN-404, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(UN-603, scope=file)
// @relation(SYS-REQ-43, scope=file)
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.BaseMessage
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import jct.pillorganizer.core.message.IotDeviceEventMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.repo.DeviceEventRepository
import jct.pillorganizer.tenant.repo.ProvisionRecordRepository
import spock.lang.Subject

@MicronautTest
class QueueProcessorServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    QueueProcessorService queueProcessorService

    @Inject
    UserService userService

    @Inject
    ProvisionRecordRepository provisionRecordRepository

    @Inject
    DeviceService deviceService

    @Inject
    DeviceEventRepository deviceEventRepository

    def "should grant a new user"() {
        given:
        def message = GrantUserMessage.builder()
                .userId("test-user-id")
                .userName("Test User")
                .email("test@example.com")
                .build()

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        def user = userService.get("test-user-id")
        user.isPresent()
        user.get().name == "Test User"
        user.get().email == "test@example.com"
    }

    def "should provision a device"() {
        given:
        def user = userService.upsert("provisioner-user", "Provisioner", "provisioner@example.com")
        def message = DeviceProvisionMessage.builder()
                .deviceId("test-device-id")
                .userId(user.id)
                .serialNo("serial-123")
                .claimId("claim-456")
                .thingName("test-thing-name")
                .build()

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        def provisionRecord = provisionRecordRepository.findById("claim-456")
        provisionRecord.isPresent()
        provisionRecord.get().serialNo == "serial-123"
        provisionRecord.get().claimId == "claim-456"
        provisionRecord.get().provisionedBy.id == user.id
    }

    def "should throw exception for invalid message type"() {
        given:
        def invalidMessage = new BaseMessage() {
            @Override
            String getType() {
                return "invalid"
            }
        }

        when:
        queueProcessorService.processQueueMessage(invalidMessage)

        then:
        thrown(IllegalStateException)
    }

    def "should persist a device event message"() {
        given:
        def user = userService.upsert("qps-event-user", "Event User", "event@example.com")
        deviceService.provision(user, "qps-event-device", "qps-serial", "qps-claim", "qps-tenant-serial-device")

        def message = IotDeviceEventMessage.builder()
                .thingName("qps-tenant-serial-device")
                .tenant("qps-tenant")
                .timestamp(1_700_000_000_000L)
                .eventType("DOOR_OPENED")
                .build()

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        def events = deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "qps-event-device" && it.eventType == "DOOR_OPENED"
        }
        events.size() == 1
        events[0].timestamp != null
    }

    def "should silently drop a duplicate device event message"() {
        given:
        def user = userService.upsert("qps-dup-user", "Dup User", "dup@example.com")
        deviceService.provision(user, "qps-dup-device", "qps-dup-serial", "qps-dup-claim", "qps-dup-thing")

        def message = IotDeviceEventMessage.builder()
                .thingName("qps-dup-thing")
                .tenant("qps-tenant")
                .timestamp(1_700_000_001_000L)
                .eventType("TAKEN")
                .build()

        when: "the same message is processed twice"
        queueProcessorService.processQueueMessage(message)
        queueProcessorService.processQueueMessage(message)

        then: "no exception is thrown and only one row exists"
        noExceptionThrown()
        def events = deviceEventRepository.findAll().findAll {
            it.logicalDevice.id == "qps-dup-device" && it.eventType == "TAKEN"
        }
        events.size() == 1
    }
}
