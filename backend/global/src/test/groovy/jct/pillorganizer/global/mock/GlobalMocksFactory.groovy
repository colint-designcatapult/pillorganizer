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
        return mockFactory.Mock(SqsClient)
    }

    @Singleton
    @Replaces(IotClient)
    IotClient iotClient() {
        return mockFactory.Mock(IotClient)
    }
}
