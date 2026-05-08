package jct.pillorganizer.global.service;

import io.micronaut.http.HttpStatus;
import io.micronaut.http.client.exceptions.HttpClientResponseException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.global.client.TenantClient;
import jct.pillorganizer.global.dto.DeviceSubscribeDto;
import jct.pillorganizer.global.model.UserEntity;
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
                                    log.atFine().log("Ignoring tenant due to Auth error (%s): %s", status.getCode(), tenant.getTenantDetails().getApiBase());
                                    return Mono.empty();
                                }
                            }

                            // 3. Propagate all other errors (Read timeouts, 500 Server Errors, etc.)
                            log.atFine().withCause(ex).log("Propagating error for tenant: %s", tenant.getTenantDetails().getApiBase());
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

    /**
     * Forwards a subscribe / unsubscribe request to the appropriate tenant module via the
     * internal API, passing the user's JWT so the tenant can authenticate the call.
     *
     * @param tenantId      tenant that owns the device
     * @param deviceId      logical device ID
     * @param user          the authenticated user entity (provides the endpoint ARN)
     * @param subscribe     {@code true} to subscribe, {@code false} to unsubscribe
     * @return updated {@link DeviceAccessDto} returned by the tenant
     */
    public Mono<DeviceAccessDto> updateDeviceNotifications(String tenantId,
                                                           String deviceId, UserEntity user,
                                                           boolean subscribe,
                                                           Boolean notifyTakeNow, Boolean notifyTaken, Boolean notifyMissed) {
        TenantClient client = tenants.stream()
                .filter(c -> tenantId.equals(c.getTenantDetails().getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Tenant not found: " + tenantId));

        String endpointArn = user.getFcmEndpointArn();
        if (subscribe && endpointArn == null) {
            return Mono.error(new IllegalStateException(
                    "User has no FCM endpoint ARN — register an FCM token first"));
        }

        DeviceSubscribeDto dto = new DeviceSubscribeDto(subscribe, endpointArn,
                notifyTakeNow, notifyTaken, notifyMissed);
        return client.updateDeviceNotifications(deviceId, dto);
    }

}
