package jct.pillorganizer.global.service

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-8, scope=file)
// @relation(CTRL-REQ-25, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(UN-603, scope=file)
// @relation(SYS-REQ-38, scope=file)
// @relation(SYS-REQ-43, scope=file)
import io.micronaut.serde.ObjectMapper
import jakarta.inject.Inject
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import software.amazon.awssdk.services.sqs.SqsClient
import spock.lang.Subject
import jct.pillorganizer.global.BaseIntegrationSpec

import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest
import software.amazon.awssdk.services.sqs.model.GetQueueUrlResponse

import software.amazon.awssdk.services.sqs.model.SendMessageRequest
import software.amazon.awssdk.services.sqs.model.SendMessageResponse
import java.util.function.Consumer

class TenantMessageServiceSpec extends BaseIntegrationSpec {

    @Inject
    SqsClient client

    @Inject
    ObjectMapper mapper

    @Inject
    @Subject
    TenantMessageService tenantMessageService

    def setup() {
        client.getQueueUrl(_ as GetQueueUrlRequest) >> { GetQueueUrlRequest req ->
            def qName = req.queueName() ?: "tenant-test-tenant"
            return GetQueueUrlResponse.builder().queueUrl("http://localhost:9324/queue/" + qName).build()
        }
    }

    def "should return correct queue URL"() {
        given:
        def tenantId = "test-tenant"

        when:
        def result = tenantMessageService.getQueueUrl(tenantId)

        then:
        result.endsWith("tenant-test-tenant")
    }

    def "should provision device"() {
        given:
        def message = DeviceProvisionMessage.builder()
                .tenantId("test-tenant")
                .deviceId("dev-456")
                .serialNo("SN-789")
                .userId("user-abc")
                .claimId("claim-xyz")
                .thingName("test-tenant-SN-789-dev-456")
                .build()

        when:
        tenantMessageService.provisionDevice(message)

        then:
        1 * client.sendMessage(_ as Consumer) >> { Consumer req ->
            def builder = SendMessageRequest.builder()
            req.accept(builder)
            def finalReq = builder.build()
            assert finalReq.messageBody().contains("test-tenant")
            assert finalReq.messageBody().contains("dev-456")
            return SendMessageResponse.builder().messageId("mocked-msg").build()
        }
    }

    def "should grant user"() {
        given:
        def message = GrantUserMessage.builder()
                .tenantId("test-tenant")
                .userId("user-abc")
                .userName("John Doe")
                .email("john@example.com")
                .build()

        when:
        tenantMessageService.grantUser(message)

        then:
        1 * client.sendMessage(_ as Consumer) >> { Consumer req ->
            def builder = SendMessageRequest.builder()
            req.accept(builder)
            def finalReq = builder.build()
            assert finalReq.messageBody().contains("test-tenant")
            assert finalReq.messageBody().contains("John Doe")
            return SendMessageResponse.builder().messageId("mocked-msg").build()
        }
    }
}
