package jct.pillorganizer.tenant.factory;

import io.micronaut.context.annotation.Factory;
import io.micronaut.context.annotation.Property;
import jakarta.inject.Singleton;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProviderChain;
import software.amazon.awssdk.regions.providers.AwsRegionProviderChain;
import software.amazon.awssdk.services.iotdataplane.IotDataPlaneClient;

import java.net.URI;
import java.util.Optional;

@Factory
public class IotClientFactory {

    @Singleton
    public IotDataPlaneClient iotDataPlaneClient(
            AwsCredentialsProviderChain credentialsProvider,
            AwsRegionProviderChain regionProvider,
            @Property(name = "aws.services.iotdataplane.endpoint-override") Optional<String> endpointOverride) {

        var builder = IotDataPlaneClient.builder()
                .credentialsProvider(credentialsProvider)
                .region(regionProvider.getRegion());

        // Apply the custom domain or ATS endpoint if it exists in the config
        endpointOverride.ifPresent(url -> builder.endpointOverride(URI.create(url)));

        return builder.build();
    }
}