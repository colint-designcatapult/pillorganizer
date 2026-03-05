package jct.pillorganizer.global.service;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.global.client.TenantClient;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.sqs.SqsClient;

import java.io.IOException;
import java.util.Collection;
import java.util.Optional;

@Singleton
@Flogger
public class TenantMessageService {

    @Inject
    SqsClient client;

    @Inject
    ObjectMapper mapper;

    @Inject
    Collection<TenantClient> clients;

    public String getQueueUrl(String tenantId) {
        /*GetQueueUrlRequest getQueueUrlRequest = GetQueueUrlRequest.builder()
                .queueName("tenant-" + tenantId)
                .build();
        return client.getQueueUrl(getQueueUrlRequest).queueUrl();*/
        return "https://sqs.ca-central-1.amazonaws.com/114829892869/tenant-" + tenantId;
    }

    public void provisionDevice(DeviceProvisionMessage message)
            throws IOException {
        String body = mapper.writeValueAsString(message);
        client.sendMessage(b -> b.messageBody(body).queueUrl(getQueueUrl(message.tenantId())));
    }

    /**
     * Notifies a Tenant that a User should have access. Crucially, this does NOT grant any specific device-user access.
     */
    public void grantUser(GrantUserMessage message) throws IOException {
        String body = mapper.writeValueAsString(message);
        client.sendMessage(b -> b.messageBody(body).queueUrl(getQueueUrl(message.tenantId())));
    }

    public Mono<DeviceClaimEligibilityDto> getDeviceClaimEligibility(String tenantId, String deviceId, String serialNumber) {
        TenantClient client = getClient(tenantId)
                .orElseThrow(() -> new IllegalStateException("Invalid tenant: " + tenantId));

        return client.getDeviceClaimEligibility(deviceId, serialNumber);
    }

    public Optional<TenantClient> getClient(String tenantId) {
        for(TenantClient client : clients) {
            if(client.getTenantDetails().getId().equals(tenantId)) {
                return Optional.of(client);
            }
        }
        return Optional.empty();
    }

}
