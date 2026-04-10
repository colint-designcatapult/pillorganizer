package jct.pillorganizer.tenant.service;

/**
 * Abstracts SNS push-notification operations so the rest of the codebase
 * stays decoupled from the AWS SDK. A local (dummy) implementation is used
 * in development and tests; the real SNS implementation is active in
 * production ("tenant" environment).
 */
public interface NotificationService {

    /**
     * Ensures an SNS topic exists for the given device, creating one if
     * necessary, and returns its ARN.
     *
     * @param deviceId logical device ID (used as part of the topic name)
     * @return ARN of the existing or newly-created SNS topic
     */
    String createOrGetTopic(String deviceId);

    /**
     * Subscribes an SNS platform endpoint to a topic.
     *
     * @param topicArn       ARN of the SNS topic
     * @param endpointArn    ARN of the user's SNS platform endpoint
     * @return subscription ARN
     */
    String subscribe(String topicArn, String endpointArn);

    /**
     * Unsubscribes a previously-created SNS subscription.
     *
     * @param subscriptionArn ARN returned by a previous {@link #subscribe} call
     */
    void unsubscribe(String subscriptionArn);

    /**
     * Publishes a plain-text push-notification message to an SNS topic.
     *
     * @param topicArn ARN of the target SNS topic
     * @param message  Human-readable message body (e.g. "It's time to take your medication")
     */
    void publish(String topicArn, String message);
}
