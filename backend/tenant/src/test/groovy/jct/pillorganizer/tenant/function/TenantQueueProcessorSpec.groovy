package jct.pillorganizer.tenant.function

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-8, scope=file)
// @relation(CTRL-REQ-25, scope=file)
// @relation(UN-404, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(SYS-REQ-43, scope=file)
import com.amazonaws.services.lambda.runtime.events.SQSEvent
import io.micronaut.serde.ObjectMapper
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.repo.ProvisionRecordRepository
import jct.pillorganizer.tenant.service.UserService
import spock.lang.Subject

@MicronautTest
class TenantQueueProcessorSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    TenantQueueProcessor tenantQueueProcessor

    @Inject
    UserService userService

    @Inject
    ProvisionRecordRepository provisionRecordRepository

    @Inject
    ObjectMapper objectMapper

    def "should process a batch of messages"() {
        given:
        def grantUserMessage = GrantUserMessage.builder()
                .userId("user-1")
                .userName("User One")
                .email("user1@example.com")
                .tenantId("tenant-1")
                .build()
        def provisionMessage = DeviceProvisionMessage.builder()
                .deviceId("device-1")
                .userId("user-1")
                .serialNo("serial-1")
                .claimId("claim-1")
                .tenantId("tenant-1")
                .thingName("tenant-1-serial-1")
                .build()
        
        def sqsEvent = new SQSEvent()
        def record1 = new SQSEvent.SQSMessage()
        record1.setBody(objectMapper.writeValueAsString(grantUserMessage))
        record1.setMessageId("msg-1")
        
        def record2 = new SQSEvent.SQSMessage()
        record2.setBody(objectMapper.writeValueAsString(provisionMessage))
        record2.setMessageId("msg-2")
        
        sqsEvent.setRecords([record1, record2])

        when:
        def response = tenantQueueProcessor.execute(sqsEvent)

        then:
        response.batchItemFailures.isEmpty()
        userService.get("user-1").isPresent()
        provisionRecordRepository.findById("claim-1").isPresent()
    }

    def "should handle processing failures"() {
        given:
        def invalidMessageBody = "invalid-json"
        
        def sqsEvent = new SQSEvent()
        def record = new SQSEvent.SQSMessage()
        record.setBody(invalidMessageBody)
        record.setMessageId("msg-fail")
        
        sqsEvent.setRecords([record])

        when:
        def response = tenantQueueProcessor.execute(sqsEvent)

        then:
        response.batchItemFailures.size() == 1
        response.batchItemFailures[0].itemIdentifier == "msg-fail"
    }
}
