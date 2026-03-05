package jct.pillorganizer.tenant.service

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.BaseMessage
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
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
                .claimToken("claim-456")
                .thingName("test-thing-name")
                .build()

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        def provisionRecord = provisionRecordRepository.findById("test-device-id")
        provisionRecord.isPresent()
        provisionRecord.get().serialNo == "serial-123"
        provisionRecord.get().claimToken == "claim-456"
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
}
