package jct.pillorganizer.global.client;

import io.micronaut.context.annotation.EachBean;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.core.type.Argument;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.annotation.Header;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import io.micronaut.http.uri.UriBuilder;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.CaregiverListItemDto;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.core.dto.DeviceEligibilityCheckDto;
import jct.pillorganizer.global.dto.DeviceSubscribeDto;
import jct.pillorganizer.global.dto.InviteCaregiverTenantDto;
import lombok.Getter;
import reactor.core.publisher.Mono;

import java.net.ConnectException;
import java.net.URI;
import java.net.UnknownHostException;
import java.util.List;

import static io.micronaut.http.HttpHeaders.AUTHORIZATION;

@EachBean(TenantDetails.class)
public class TenantClient {

    private final HttpClient httpClient;
    @Getter
    private final TenantDetails tenantDetails;

    public TenantClient(@Client(value = "/", id = "tenant") HttpClient httpClient, TenantDetails tenantDetails) {
        this.httpClient = httpClient;
        this.tenantDetails = tenantDetails;
    }

    private String makeUri(String api) {
        return tenantDetails.getApiBase() + api;
    }

    public Mono<List<DeviceAccessDto>> getDeviceAccess() {
        return Mono.from(httpClient.retrieve(HttpRequest.GET(makeUri("/internal/user/devices")),
                Argument.listOf(DeviceAccessDto.class)));
    }

    public Mono<Boolean> healthCheck() {
        return Mono.from(httpClient.retrieve(HttpRequest.GET(makeUri("/health")),
                Argument.of(Boolean.class)));
    }

    public Mono<String> getDeviceAccessPolicyDocument(String authorization, String deviceId) {
        URI uri = UriBuilder.of(makeUri("/internal/user/device_access_policy"))
                .queryParam("deviceId", deviceId)
                .build();
        return Mono.from(httpClient.retrieve(
                HttpRequest.GET(uri).bearerAuth(authorization)
        ));
    }

    public Mono<DeviceClaimEligibilityDto> getDeviceClaimEligibility(String deviceId, String serialNumber) {
        return Mono.from(httpClient.retrieve(HttpRequest.POST(makeUri("/internal/user/device_claim_eligibility"),
                new DeviceEligibilityCheckDto(deviceId, serialNumber)), Argument.of(DeviceClaimEligibilityDto.class)));
    }

    public Mono<DeviceAccessDto> updateDeviceNotifications(String deviceId,
                                                           DeviceSubscribeDto dto) {
        return Mono.from(httpClient.retrieve(
                HttpRequest.POST(makeUri("/internal/user/device/" + deviceId + "/notifications"), dto),
                Argument.of(DeviceAccessDto.class)));
    }

    public Mono<CaregiverListItemDto> inviteCaregiver(String deviceId, InviteCaregiverTenantDto dto) {
        return Mono.from(httpClient.retrieve(
                HttpRequest.POST(makeUri("/internal/user/device/" + deviceId + "/invite-caregiver"), dto),
                Argument.of(CaregiverListItemDto.class)));
    }

    public static boolean isConnectionInitializationFailure(Throwable ex) {
        Throwable cause = ex;
        while (cause != null) {
            if (cause instanceof UnknownHostException || cause instanceof ConnectException) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }

}
