package jct.pillorganizer.core.factory;

import io.micronaut.context.annotation.Factory;
import jakarta.inject.Singleton;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProviderChain;
import software.amazon.awssdk.regions.providers.AwsRegionProviderChain;
import software.amazon.awssdk.services.cognitoidentityprovider.CognitoIdentityProviderClient;

@Factory
public class CognitoFactory {

    @Singleton
    public CognitoIdentityProviderClient cognitoIdentityProviderClient(
            AwsCredentialsProviderChain credentialsProvider,
            AwsRegionProviderChain regionProvider) {
        return CognitoIdentityProviderClient.builder()
                .credentialsProvider(credentialsProvider)
                .region(regionProvider.getRegion())
                .build();
    }

}
