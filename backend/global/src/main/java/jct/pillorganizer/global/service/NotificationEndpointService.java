package jct.pillorganizer.global.service;

/**
 * Abstracts SNS platform-endpoint registration so the rest of the control-plane
 * stays decoupled from the AWS SDK.
 * A local (dummy) implementation is used in development/tests;
 * the real SNS implementation is active in the {@code global} environment.
 */
public interface NotificationEndpointService {

    /**
     * Registers or refreshes an FCM token as an SNS platform-application endpoint.
     * If an endpoint ARN already exists for this user it is updated in-place;
     * otherwise a new endpoint is created.
     *
     * @param fcmToken       current Firebase Cloud Messaging registration token
     * @param existingEndpointArn the user's current endpoint ARN, or {@code null} if none
     * @return the (possibly new) SNS endpoint ARN
     */
    String registerOrUpdateEndpoint(String fcmToken, String existingEndpointArn);
}
