package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.iot.IotClient;

/**
 * Production implementation of {@link IotThingService}.
 * Deletes IoT Things via the AWS IoT control-plane API.
 * Active in the {@code tenant} environment.
 */
@Flogger
@Singleton
@Requires(env = "tenant")
public class AwsIotThingService implements IotThingService {

    private final IotClient iotClient;

    public AwsIotThingService(IotClient iotClient) {
        this.iotClient = iotClient;
    }

    @Override
    public void deleteThing(String thingName) {
        log.atInfo().log("Deleting IoT Thing: %s", thingName);
        iotClient.deleteThing(b -> b.thingName(thingName));
    }
}
