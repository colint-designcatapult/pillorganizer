package jct.pillorganizer.global.service

import io.micronaut.serde.ObjectMapper
import jakarta.inject.Inject
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import software.amazon.awssdk.services.sqs.SqsClient
import spock.lang.Subject
import jct.pillorganizer.global.BaseIntegrationSpec

class TenantMessageServiceSpec extends BaseIntegrationSpec {

    @Inject
    SqsClient client

    @Inject
    ObjectMapper mapper

    @Inject
    @Subject
    TenantMessageService tenantMessageService

    def "should return correct queue URL"() {
        given:
        def tenantId = "test-tenant"

        when:
        def result = tenantMessageService.getQueueUrl(tenantId)

        then:
        result.contains("tenant-test-tenant")
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
        def queueUrl = tenantMessageService.getQueueUrl("test-tenant")

        when:
        tenantMessageService.provisionDevice(message)

        then:
        noExceptionThrown()
        
        and:
        def response = client.receiveMessage(b -> b.queueUrl(queueUrl).maxNumberOfMessages(1))
        response.hasMessages()
        response.messages().get(0).body().contains("test-tenant")
        response.messages().get(0).body().contains("dev-456")
    }

    def "should grant user"() {
        given:
        def message = GrantUserMessage.builder()
                .tenantId("test-tenant")
                .userId("user-abc")
                .userName("John Doe")
                .email("john@example.com")
                .build()
        def queueUrl = tenantMessageService.getQueueUrl("test-tenant")

        when:
        tenantMessageService.grantUser(message)

        then:
        noExceptionThrown()

        and:
        def response = client.receiveMessage(b -> b.queueUrl(queueUrl).maxNumberOfMessages(1))
        response.hasMessages()
        response.messages().get(0).body().contains("test-tenant")
        response.messages().get(0).body().contains("John Doe")
    }
}
