package jct.pillorganizer.tenant.function

import com.amazonaws.services.lambda.runtime.events.SQSBatchResponse
import com.amazonaws.services.lambda.runtime.events.SQSEvent
import io.micronaut.serde.ObjectMapper
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.device.Device
import jct.pillorganizer.tenant.model.user.User
import jct.pillorganizer.tenant.service.DeviceService
import jct.pillorganizer.tenant.service.DeviceUserService
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
    DeviceService deviceService

    @Inject
    DeviceUserService deviceUserService

    @Inject
    ObjectMapper objectMapper

    def "execute should process GrantUserMessage successfully"() {
        given:
        String userId = "user-grant-sqs"
        String userName = "Grant User SQS"
        String email = "grant.sqs@example.com"
        GrantUserMessage message = new GrantUserMessage(userId, userName, email)
        
        SQSEvent.SQSMessage sqsMessage = new SQSEvent.SQSMessage()
        sqsMessage.setBody(objectMapper.writeValueAsString(message))
        sqsMessage.setMessageId("msg-1")
        
        SQSEvent event = new SQSEvent()
        event.setRecords([sqsMessage])

        when:
        SQSBatchResponse response = tenantQueueProcessor.execute(event)

        then:
        response.batchItemFailures.isEmpty()
        
        and:
        Optional<User> user = userService.get(userId)
        user.isPresent()
        user.get().name == userName
        user.get().email == email
    }

    def "execute should process DeviceProvisionMessage successfully"() {
        given:
        String userId = "user-prov-sqs"
        String deviceId = "device-prov-sqs"
        String serialNo = "SN-PROV-SQS"
        String claimToken = "token-prov-sqs"
        
        // User must exist first
        User user = userService.upsert(userId, "Prov User SQS", "prov.sqs@example.com")
        
        DeviceProvisionMessage message = new DeviceProvisionMessage(claimToken, deviceId, userId, serialNo)
        
        SQSEvent.SQSMessage sqsMessage = new SQSEvent.SQSMessage()
        sqsMessage.setBody(objectMapper.writeValueAsString(message))
        sqsMessage.setMessageId("msg-2")
        
        SQSEvent event = new SQSEvent()
        event.setRecords([sqsMessage])

        when:
        SQSBatchResponse response = tenantQueueProcessor.execute(event)

        then:
        response.batchItemFailures.isEmpty()
        
        and:
        Device device = deviceService.findById(deviceId)
        device != null
        device.serialNo == serialNo
        
        and:
        deviceUserService.doesUserBelongToDevice(user, device)
    }

    def "execute should report failure for invalid message"() {
        given:
        SQSEvent.SQSMessage sqsMessage = new SQSEvent.SQSMessage()
        sqsMessage.setBody("invalid-json")
        sqsMessage.setMessageId("msg-3")
        
        SQSEvent event = new SQSEvent()
        event.setRecords([sqsMessage])

        when:
        SQSBatchResponse response = tenantQueueProcessor.execute(event)

        then:
        response.batchItemFailures.size() == 1
        response.batchItemFailures[0].itemIdentifier == "msg-3"
    }
}
