package jct.pillorganizer.global.mock

import io.micronaut.context.annotation.Factory
import io.micronaut.context.annotation.Requires
import jakarta.inject.Singleton
import io.micronaut.context.annotation.Replaces
import software.amazon.awssdk.services.iot.IotClient
import software.amazon.awssdk.services.sqs.SqsClient
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest
import software.amazon.awssdk.services.sqs.model.GetQueueUrlResponse
import software.amazon.awssdk.services.sqs.model.SendMessageRequest
import software.amazon.awssdk.services.sqs.model.SendMessageResponse
import software.amazon.awssdk.services.sqs.model.Message
import software.amazon.awssdk.services.sqs.model.ReceiveMessageResponse
import spock.mock.DetachedMockFactory

@Factory
@Requires(env = "test")
class GlobalMocksFactory {
    DetachedMockFactory mockFactory = new DetachedMockFactory()

    @Singleton
    @Replaces(SqsClient)
    SqsClient sqsClient() {
        def messages = []
        return [
            getQueueUrl: { req ->
                def finalReq = req
                if (req instanceof java.util.function.Consumer) {
                    def builder = GetQueueUrlRequest.builder()
                    req.accept(builder)
                    finalReq = builder.build()
                }
                def qName = finalReq.queueName() ?: "tenant-test-tenant"
                GetQueueUrlResponse.builder().queueUrl("http://localhost:9324/queue/" + qName).build()
            },
            sendMessage: { req ->
                def finalReq = req
                if (req instanceof java.util.function.Consumer) {
                    def builder = SendMessageRequest.builder()
                    req.accept(builder)
                    finalReq = builder.build()
                }
                messages.add(finalReq)
                SendMessageResponse.builder().messageId("mocked-msg").build()
            },
            receiveMessage: { req ->
                def items = messages.collect { Message.builder().body(it.messageBody()).build() }
                messages.clear()
                ReceiveMessageResponse.builder().messages(items).build()
            }
        ] as SqsClient
    }

    @Singleton
    @Replaces(IotClient)
    IotClient iotClient() {
        return [:] as IotClient
    }
}
