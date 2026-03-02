package jct.pillorganizer.global.client;

import io.micronaut.context.annotation.EachBean;
import io.micronaut.core.type.Argument;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import reactor.core.publisher.Mono;

import java.util.List;

@EachBean(TenantDetails.class)
public class TenantClient {

    private final HttpClient httpClient;
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
}
