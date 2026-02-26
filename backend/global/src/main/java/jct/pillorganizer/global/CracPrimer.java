package jct.pillorganizer.global;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import io.micronaut.crac.resources.NettyEmbeddedServerResource;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import io.micronaut.http.client.exceptions.HttpClientException;
import io.micronaut.management.endpoint.health.HealthEndpoint;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.client.TenantClient;
import jct.pillorganizer.global.model.BaseControlPlaneEntity;
import jct.pillorganizer.global.repo.BaseControlPlaneRepo;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.service.UserDeviceAccessService;
import org.crac.Context;
import org.crac.Resource;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.GetItemRequest;
import software.amazon.awssdk.services.dynamodb.model.ListTablesRequest;

import java.time.Duration;
import java.util.Collection;
import java.util.Map;

@Singleton
@Requires(notEnv = "test")
public class CracPrimer implements OrderedResource {
    private final DeviceRepo deviceRepo;
    private final UserDeviceAccessService userDeviceAccessService;

    @Inject
    public CracPrimer(DeviceRepo deviceRepo, UserDeviceAccessService userDeviceAccessService) {
        this.deviceRepo = deviceRepo;
        this.userDeviceAccessService = userDeviceAccessService;
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        deviceRepo.get("test", "test");
        try {
            userDeviceAccessService.getUserDeviceAccess();
        } catch (Exception ex) {
            // Swallow exception: just need to prime the client, doesn't need to succeed
        }
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }

    @Override
    public int getOrder() {
        // Move down the order so HTTP server is initialized
        return 1;
    }
}
