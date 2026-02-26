package jct.pillorganizer.global.client;

import io.micronaut.context.annotation.EachBean;
import io.micronaut.core.type.Argument;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import org.reactivestreams.Publisher;
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

    public Mono<List<DeviceAccessDto>> getDeviceAccess() {
        String uri = tenantDetails.getApiBase() + "/api/v1/user/devices";
        return Mono.from(httpClient.retrieve(HttpRequest.GET(uri), Argument.listOf(DeviceAccessDto.class)));
    }
}
