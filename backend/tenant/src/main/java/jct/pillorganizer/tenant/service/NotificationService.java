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
     * Publishes a push-notification message to an SNS topic.
     *
     * @param topicArn   ARN of the target SNS topic
     * @param title      Human-readable title (e.g. "Medication Reminder")
     * @param body       Human-readable message body (e.g. "It's time to take your medication")
     * @param ttlSeconds Number of seconds the message should remain deliverable. The FCM
     *                   {@code android.ttl} field and the SNS {@code AWS.SNS.MOBILE.GCM.TTL}
     *                   message attribute are both set to this value. Must be &gt; 0.
     * @param eventType  The event type for SNS filter policy matching (e.g. "TAKE_NOW", "TAKEN", "MISSED")
     */
    void publish(String topicArn, String title, String body, long ttlSeconds, String eventType);

    /**
     * Updates the SNS filter policy on a subscription to block specific event types.
     * Messages whose {@code event_type} attribute matches any entry in
     * {@code blockedEventTypes} will <em>not</em> be delivered. Messages with no
     * {@code event_type} attribute are always delivered regardless of this list.
     * Pass an empty list to clear the filter and deliver all event types.
     *
     * @param subscriptionArn  the subscription to configure
     * @param blockedEventTypes event types to suppress (e.g. ["TAKE_NOW", "MISSED"]);
     *                          empty list clears the filter entirely
     */
    void setFilterPolicy(String subscriptionArn, java.util.List<String> blockedEventTypes);
}
