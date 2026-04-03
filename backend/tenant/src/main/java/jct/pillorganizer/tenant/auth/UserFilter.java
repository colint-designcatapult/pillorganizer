package jct.pillorganizer.tenant.auth;

import io.micronaut.core.order.Ordered;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.annotation.RequestFilter;
import io.micronaut.http.annotation.ServerFilter;
import io.micronaut.http.filter.ServerFilterPhase;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.service.RequestCacheService;

@ServerFilter(io.micronaut.http.annotation.Filter.MATCH_ALL_PATTERN)
public class UserFilter implements Ordered {

    @Inject
    RequestCacheService requestCacheService;

    @RequestFilter
    void filterRequest(HttpRequest<?> request) {
        requestCacheService.processRequest(request);
    }

    @Override
    public int getOrder() {
        return ServerFilterPhase.SECURITY.after();
    }
}
