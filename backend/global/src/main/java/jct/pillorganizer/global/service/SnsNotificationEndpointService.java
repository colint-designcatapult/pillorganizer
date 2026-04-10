package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.*;

/**
 * Production SNS implementation of {@link NotificationEndpointService}.
 * Active in the {@code global} (control-plane) environment.
 */
@Singleton
@Flogger
@Requires(env = "global")
public class SnsNotificationEndpointService implements NotificationEndpointService {

    static final String PLATFORM_APPLICATION_ARN =
            "arn:aws:sns:ca-central-1:114829892869:app/GCM/HealtheCabinetAndroid";

    private final SnsClient snsClient;

    public SnsNotificationEndpointService(SnsClient snsClient) {
        this.snsClient = snsClient;
    }

    @Override
    public String registerOrUpdateEndpoint(String fcmToken, String existingEndpointArn) {
        if (existingEndpointArn != null) {
            try {
                // Update the token on the existing endpoint
                snsClient.setEndpointAttributes(SetEndpointAttributesRequest.builder()
                        .endpointArn(existingEndpointArn)
                        .attributes(java.util.Map.of("Token", fcmToken, "Enabled", "true"))
                        .build());
                log.atInfo().log("Updated SNS endpoint %s with new FCM token", existingEndpointArn);
                return existingEndpointArn;
            } catch (InvalidParameterException e) {
                log.atWarning().withCause(e).log(
                        "Existing endpoint %s is invalid, creating new one", existingEndpointArn);
            }
        }

        CreatePlatformEndpointResponse response = snsClient.createPlatformEndpoint(
                CreatePlatformEndpointRequest.builder()
                        .platformApplicationArn(PLATFORM_APPLICATION_ARN)
                        .token(fcmToken)
                        .build());
        log.atInfo().log("Created new SNS endpoint: %s", response.endpointArn());
        return response.endpointArn();
    }
}
