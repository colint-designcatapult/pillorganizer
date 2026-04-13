package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;

import java.util.concurrent.atomic.AtomicLong;

/**
 * Local / test implementation of {@link NotificationEndpointService}.
 * Returns deterministic fake ARNs without touching AWS.
 * Active in {@code local} and {@code test} environments.
 */
@Singleton
@Flogger
@Requires(env = {"local", "test"})
public class LocalNotificationEndpointService implements NotificationEndpointService {

    private final AtomicLong counter = new AtomicLong(1);

    @Override
    public String registerOrUpdateEndpoint(String fcmToken, String existingEndpointArn) {
        if (existingEndpointArn != null) {
            log.atInfo().log("Local: refreshed endpoint %s with new FCM token", existingEndpointArn);
            return existingEndpointArn;
        }
        String arn = "arn:local:sns:local:000000000000:endpoint/GCM/HealtheCabinetAndroid/"
                + counter.getAndIncrement();
        log.atInfo().log("Local: created endpoint %s for token %s", arn, fcmToken);
        return arn;
    }
}
