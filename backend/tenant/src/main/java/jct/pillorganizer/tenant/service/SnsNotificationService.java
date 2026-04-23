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
import java.time.Instant;
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

    public String buildFinalSnsPayload(String title, String body, String channelId, long ttlInSeconds) throws IOException {
        // 1. Calculate APNs Expiration (Absolute Epoch Time)
        long apnsExpirationEpoch = Instant.now().getEpochSecond() + ttlInSeconds;

        // 2. Build the deeply nested GCM/FCM Data Structure
        var gcmPayload = new GcmPayload(
                new FcmV1Message(
                        new Message(
                                new Notification(title, body),
                                new AndroidConfig(
                                        ttlInSeconds + "s",
                                        "HIGH",
                                        new AndroidNotification(channelId)
                                ),
                                new ApnsConfig(
                                        new ApnsHeaders(
                                                String.valueOf(apnsExpirationEpoch),
                                                "10"
                                        )
                                )
                        )
                )
        );

        // 3. Serialize the GcmPayload to a JSON String
        String stringifiedGcm = objectMapper.writeValueAsString(gcmPayload);

        // 4. Build the top-level SNS Message
        var snsMessage = new SnsMessage(
                body,           // Fallback text
                stringifiedGcm // The stringified JSON from step 3
        );

        // 5. Serialize the entire SNS Message for the AWS SDK `Message` parameter
        return objectMapper.writeValueAsString(snsMessage);
    }

    @Override
    public void publish(String topicArn, String title, String body, long ttlSeconds) {
        try {
            String snsMessage = buildFinalSnsPayload(title, body, "medication_reminders", ttlSeconds);
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

    // 1. The top-level SNS Message Object
    @Serdeable
    record SnsMessage(
            @JsonProperty("default") String defaultMessage,
            @JsonProperty("GCM") String gcm // This MUST be the stringified GcmPayload
    ) {}

    // 2. The GCM Payload Wrapper
    @Serdeable
    record GcmPayload(
            @JsonProperty("fcmV1Message") FcmV1Message fcmV1Message
    ) {}

    @Serdeable
    record FcmV1Message(
            @JsonProperty("message") Message message
    ) {}

    // 3. The Core Message Structure
    @Serdeable
    record Message(
            @JsonProperty("notification") Notification notification,
            @JsonProperty("android") AndroidConfig android,
            @JsonProperty("apns") ApnsConfig apns
    ) {}

    @Serdeable
    record Notification(
            @JsonProperty("title") String title,
            @JsonProperty("body") String body
    ) {}

    // 4. Android Specific Overrides
    @Serdeable
    record AndroidConfig(
            @JsonProperty("ttl") String ttl, // e.g., "86400s"
            @JsonProperty("priority") String priority, // "HIGH" or "NORMAL"
            @JsonProperty("notification") AndroidNotification notification
    ) {}

    @Serdeable
    record AndroidNotification(
            @JsonProperty("channel_id") String channelId
    ) {}

    // 5. iOS (APNs) Specific Overrides
    @Serdeable
    record ApnsConfig(
            @JsonProperty("headers") ApnsHeaders headers
    ) {}

    @Serdeable
    record ApnsHeaders(
            @JsonProperty("apns-expiration") String apnsExpiration, // Absolute epoch time string
            @JsonProperty("apns-priority") String apnsPriority      // "10" (immediate) or "5" (background)
    ) {}

}
