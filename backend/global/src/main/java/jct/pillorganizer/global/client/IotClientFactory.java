package jct.pillorganizer.global.client;

import io.micronaut.context.annotation.Factory;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.iot.IotClient;

@Factory
public class IotClientFactory {

    @Value("${aws.region}")
    protected String awsRegion;

    @Singleton
    public IotClient iotClient() {
        return IotClient.builder()
                .region(Region.of(awsRegion))
                .build();
    }

}
