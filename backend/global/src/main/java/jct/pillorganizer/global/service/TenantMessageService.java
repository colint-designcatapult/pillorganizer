package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.core.message.DeleteUserMessage;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.core.message.NoOpMessage;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.global.client.TenantClient;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.QueueDoesNotExistException;

import java.io.IOException;
import java.time.Duration;
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

    @Inject
    TenantService tenantService;

    public String getQueueUrl(String tenantId) {
        GetQueueUrlRequest request = GetQueueUrlRequest.builder()
                // No need for queueOwnerAWSAccountId!
                .queueName("tenant-" + tenantId)
                .build();

        return client.getQueueUrl(request).queueUrl();    }

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

    /**
     * Sends a deleteUser message to every tenant's queue.
     * Silently swallows errors for tenants whose queue does not exist;
     * rethrows unexpected failures.
     */
    public void broadcastDeleteUser(DeleteUserMessage message) throws IOException {
        String body = mapper.writeValueAsString(message);
        for (TenantDetails tenant : tenantService.getTenantList()) {
            try {
                String queueUrl = getQueueUrl(tenant.getId());
                client.sendMessage(b -> b.messageBody(body).queueUrl(queueUrl));
                log.atInfo().log("Sent deleteUser message to tenant %s", tenant.getId());
            } catch (QueueDoesNotExistException e) {
                log.atInfo().log("Queue does not exist for tenant %s, skipping", tenant.getId());
            }
        }
    }

    /**
     * Primes the resources this service uses for cold starts/CRaC.
     */
    public void primeService(String tenantId) throws IOException {
        // Prime object mapper
        String body = mapper.writeValueAsString(new NoOpMessage());

        // Prime SQS
        String queueUrl = getQueueUrl(tenantId);
        client.sendMessage(b -> b.messageBody(body).queueUrl(queueUrl));

        // Prime health checks
        for(TenantClient tenant : this.clients) {
            tenant.healthCheck()
                    .blockOptional(Duration.ofSeconds(1));
        }
    }

}
