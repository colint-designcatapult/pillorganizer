package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.*;
import io.micronaut.serde.ObjectMapper;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.serde.annotation.Serdeable;

import java.io.IOException;

/**
 * Production SNS implementation of {@link NotificationService}.
 * Active when the {@code tenant} environment is loaded.
 */
@Singleton
@Flogger
@Requires(env = "tenant")
public class SnsNotificationService implements NotificationService {

    private final SnsClient snsClient;
    private final ObjectMapper objectMapper;

    public SnsNotificationService(SnsClient snsClient, ObjectMapper objectMapper) {
        this.snsClient = snsClient;
        this.objectMapper = objectMapper;
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
    public void publish(String topicArn, String title, String body) {
        try {
            NotificationData notificationData = new NotificationData(title, body);

            FcmMessageWrapper fcmMessage = new FcmMessageWrapper(
                    new FcmMessage(
                            new FcmNotification(notificationData)
                    )
            );

            DefaultPayload defaultPayload = new DefaultPayload(notificationData);

            String gcmPayloadStr = objectMapper.writeValueAsString(fcmMessage);
            String defaultPayloadStr = objectMapper.writeValueAsString(defaultPayload);

            SnsPayload snsPayload = new SnsPayload(gcmPayloadStr, defaultPayloadStr);

            String snsMessage = objectMapper.writeValueAsString(snsPayload);

            snsClient.publish(PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(snsMessage)
                    .messageStructure("json")
                    .build());
            log.atInfo().log("SNS message published to topic %s", topicArn);
        } catch (IOException e) {
            log.atWarning().withCause(e).log("Failed to serialize SNS message for topic %s", topicArn);
            throw new RuntimeException("Failed to serialize SNS message", e);
        }
    }

    @Serdeable
    public record SnsPayload(
            @JsonProperty("GCM") String gcm,
            @JsonProperty("default") String defaultPayload
    ) {}

    @Serdeable
    public record FcmMessageWrapper(FcmMessage fcmV1Message) {}

    @Serdeable
    public record FcmMessage(FcmNotification message) {}

    @Serdeable
    public record FcmNotification(NotificationData notification) {}

    @Serdeable
    public record DefaultPayload(NotificationData notification) {}

    @Serdeable
    public record NotificationData(String title, String body) {}
}
