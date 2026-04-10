package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.*;

/**
 * Production SNS implementation of {@link NotificationService}.
 * Active when the {@code tenant} environment is loaded.
 */
@Singleton
@Flogger
@Requires(env = "tenant")
public class SnsNotificationService implements NotificationService {

    private final SnsClient snsClient;

    public SnsNotificationService(SnsClient snsClient) {
        this.snsClient = snsClient;
    }

    @Override
    public String createOrGetTopic(String deviceId) {
        String topicName = "device-" + deviceId;
        CreateTopicResponse response = snsClient.createTopic(
                CreateTopicRequest.builder().name(topicName).build());
        log.atInfo().log("Ensured SNS topic for device %s: %s", deviceId, response.topicArn());
        return response.topicArn();
    }

    @Override
    public String subscribe(String topicArn, String endpointArn) {
        SubscribeResponse response = snsClient.subscribe(SubscribeRequest.builder()
                .topicArn(topicArn)
                .protocol("application")
                .endpoint(endpointArn)
                .build());
        log.atInfo().log("SNS subscription created: %s", response.subscriptionArn());
        return response.subscriptionArn();
    }

    @Override
    public void unsubscribe(String subscriptionArn) {
        snsClient.unsubscribe(UnsubscribeRequest.builder()
                .subscriptionArn(subscriptionArn)
                .build());
        log.atInfo().log("SNS subscription deleted: %s", subscriptionArn);
    }

    @Override
    public void publish(String topicArn, String message) {
        snsClient.publish(PublishRequest.builder()
                .topicArn(topicArn)
                .message(message)
                .build());
        log.atInfo().log("SNS message published to topic %s", topicArn);
    }
}
