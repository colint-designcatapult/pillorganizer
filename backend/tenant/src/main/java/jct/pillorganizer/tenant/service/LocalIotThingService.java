package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;

/**
 * Local / test implementation of {@link IotThingService}.
 * Prints delete operations to console without touching AWS IoT Core.
 * Active in local and test environments.
 */
@Flogger
@Singleton
@Requires(env = {"local", "test"})
public class LocalIotThingService implements IotThingService {

    @Override
    public void deleteThing(String thingName) {
        log.atInfo().log("Local: would delete IoT Thing: %s", thingName);
    }
}
