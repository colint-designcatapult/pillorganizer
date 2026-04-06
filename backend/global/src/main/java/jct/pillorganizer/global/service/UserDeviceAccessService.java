package jct.pillorganizer.global.service;

import io.micronaut.http.HttpStatus;
import io.micronaut.http.client.exceptions.HttpClientException;
import io.micronaut.http.client.exceptions.HttpClientResponseException;
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
                        .onErrorResume(ex -> {
                            // 1. Swallow connection initiation failures
                            if (TenantClient.isConnectionInitializationFailure(ex)) {
                                log.atFine().log("Ignoring unreachable tenant (Connection Failed): {}", tenant.getTenantDetails().getApiBase());
                                return Mono.empty();
                            }

                            // 2. Swallow authorization errors (401 Unauthorized, 403 Forbidden)
                            if (ex instanceof HttpClientResponseException) {
                                HttpClientResponseException httpEx = (HttpClientResponseException) ex;
                                HttpStatus status = httpEx.getStatus();

                                if (status == HttpStatus.UNAUTHORIZED || status == HttpStatus.FORBIDDEN) {
                                    log.atFine().log("Ignoring tenant due to Auth error ({}): {}", status.getCode(), tenant.getTenantDetails().getApiBase());
                                    return Mono.empty();
                                }
                            }

                            // 3. Propagate all other errors (Read timeouts, 500 Server Errors, etc.)
                            log.atFine().log("Propagating error for tenant: {}", tenant.getTenantDetails().getApiBase(), ex);
                            return Mono.error(ex);
                        })
                );
    }


    public Mono<String> getUserDeviceAccessPolicyDocument(String jwt, String tenantId, String deviceId) {
        TenantClient client = tenants.stream().filter(c -> tenantId.equals(c.getTenantDetails().getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Tenant not found: " + tenantId));

        return client.getDeviceAccessPolicyDocument(jwt, deviceId);
    }

}
