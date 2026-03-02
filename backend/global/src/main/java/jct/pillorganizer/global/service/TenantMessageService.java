package jct.pillorganizer.global.service;

import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.sqs.SqsClient;

import java.io.IOException;

@Singleton
@Flogger
public class TenantMessageService {

    @Inject
    SqsClient client;

    @Inject
    ObjectMapper mapper;

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

}
