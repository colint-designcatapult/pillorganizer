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
import java.util.Map;

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
    public void publish(String topicArn, String title, String body, long ttlSeconds) {
        try {
            NotificationData notificationData = new NotificationData(title, body);

            // Assemble the core FCM message body with Android and APNs configurations
            FcmMessageBody messageBody = new FcmMessageBody(
                    notificationData,
                    new FcmAndroid(ttlSeconds + "s", new FcmAndroidNotification("medication_reminders")),
                    new FcmApns(new FcmApnsPayload(new FcmAps("default"))) // Add default sound for iOS
            );

            // Wrap it correctly for the SNS GCM FCMv1 structure
            FcmMessageWrapper fcmMessage = new FcmMessageWrapper(new FcmMessage(messageBody));

            DefaultPayload defaultPayload = new DefaultPayload(notificationData);

            String gcmPayloadStr = objectMapper.writeValueAsString(fcmMessage);
            String defaultPayloadStr = objectMapper.writeValueAsString(defaultPayload);

            SnsPayload snsPayload = new SnsPayload(gcmPayloadStr, defaultPayloadStr);

            String snsMessage = objectMapper.writeValueAsString(snsPayload);

            snsClient.publish(PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(snsMessage)
                    .messageStructure("json")
                    .messageAttributes(Map.of(
                            "AWS.SNS.MOBILE.GCM.TTL", MessageAttributeValue.builder()
                                    .dataType("Number")
                                    .stringValue(String.valueOf(ttlSeconds))
                                    .build()
                    ))
                    .build());
            log.atInfo().log("SNS message published to topic %s (ttl=%ds)", topicArn, ttlSeconds);
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

    // Top-level wrapper required by AWS Pinpoint/SNS for FCM v1
    @Serdeable
    public record FcmMessageWrapper(FcmMessage fcmV1Message) {}

    // Forces the "message" key root inside fcmV1Message
    @Serdeable
    public record FcmMessage(FcmMessageBody message) {}

    // Notification, Android, and APNs are now correctly siblings inside the "message" object
    @Serdeable
    public record FcmMessageBody(
            NotificationData notification,
            FcmAndroid android,
            FcmApns apns
    ) {}

    @Serdeable
    public record FcmAndroid(@JsonProperty("ttl") String ttl, FcmAndroidNotification notification) {}

    @Serdeable
    public record FcmAndroidNotification(@JsonProperty("channel_id") String channelId) {}

    @Serdeable
    public record FcmApns(FcmApnsPayload payload) {}

    @Serdeable
    public record FcmApnsPayload(FcmAps aps) {}

    @Serdeable
    public record FcmAps(String sound) {}

    @Serdeable
    public record DefaultPayload(NotificationData notification) {}

    @Serdeable
    public record NotificationData(String title, String body) {}
}
