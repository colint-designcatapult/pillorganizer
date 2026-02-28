package jct.pillorganizer.tenant.service;

import io.micronaut.http.context.ServerRequestContext;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;

import java.util.Optional;

@Singleton
public class TenantServiceImpl implements TenantService {

    private static final String ATTRIBUTE_TENANT = "tenantIdentifier";

    @Inject
    jct.pillorganizer.core.TenantService coreTenantService;

    @Override
    public Optional<TenantDetails> getCurrentTenant() {
        return ServerRequestContext.currentRequest()
                .flatMap(request -> request.getAttribute(ATTRIBUTE_TENANT, String.class))
                .flatMap(tenantId -> coreTenantService.getTenantDetails(tenantId));
    }
}
