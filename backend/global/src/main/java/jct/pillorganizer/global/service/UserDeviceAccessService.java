package jct.pillorganizer.global.service;

import io.micronaut.http.client.exceptions.HttpClientException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.global.client.TenantClient;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Collection;

@Flogger
@Singleton
public class UserDeviceAccessService {

    @Inject
    Collection<TenantClient> tenants;

    public Flux<DeviceAccessDto> getUserDeviceAccess() {
        // Perform a scatter-gather query on all tenants
        return Flux.fromIterable(tenants)
                // Query the device access list from all the tenants
                .flatMap(tenant -> tenant.getDeviceAccess()
                        // Merge the results (getDeviceAccess returns list, merge list into flux)
                        .flatMapMany(Flux::fromIterable)
                        // Keep going on HTTP error
                        .onErrorResume(
                                ex -> ex instanceof HttpClientException,
                                ex -> Mono.empty()
                        )
                );
    }


    public Mono<String> getUserDeviceAccessPolicyDocument(String jwt, String tenantId, String thingName) {
        TenantClient client = tenants.stream().filter(c -> tenantId.equals(c.getTenantDetails().getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Tenant not found: " + tenantId));

        return client.getDeviceAccessPolicyDocument(jwt, thingName);
    }

}
