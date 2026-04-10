package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Local / test implementation of {@link NotificationService}.
 * Emulates SNS semantics (returning fake ARNs) without touching AWS.
 * Active in every environment that is NOT the {@code tenant} production environment.
 */
@Singleton
@Flogger
@Requires(env = {"local", "test"})
public class LocalNotificationService implements NotificationService {

    private final ConcurrentHashMap<String, String> topics = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> subscriptions = new ConcurrentHashMap<>();
    private final AtomicLong counter = new AtomicLong(1);

    @Override
    public String createOrGetTopic(String deviceId) {
        return topics.computeIfAbsent(deviceId, id -> {
            String arn = "arn:local:sns:local:000000000000:device-" + id;
            log.atInfo().log("Local: created topic for device %s -> %s", id, arn);
            return arn;
        });
    }

    @Override
    public String subscribe(String topicArn, String endpointArn) {
        String subscriptionArn = topicArn + ":sub-" + counter.getAndIncrement();
        subscriptions.put(subscriptionArn, endpointArn);
        log.atInfo().log("Local: subscribed endpoint %s to topic %s -> %s", endpointArn, topicArn, subscriptionArn);
        return subscriptionArn;
    }

    @Override
    public void unsubscribe(String subscriptionArn) {
        subscriptions.remove(subscriptionArn);
        log.atInfo().log("Local: unsubscribed %s", subscriptionArn);
    }

    @Override
    public void publish(String topicArn, String title, String body) {
        log.atInfo().log("Local: publish to %s — title: %s, body: %s", topicArn, title, body);
    }
}
