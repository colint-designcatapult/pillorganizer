package jct.pillorganizer.tenant;

import io.micronaut.context.annotation.Requires;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.http.server.util.HttpHostResolver;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import io.micronaut.multitenancy.tenantresolver.AbstractSubdomainTenantResolver;
import io.micronaut.multitenancy.tenantresolver.TenantResolver;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.service.ConfigTenantService;
import jct.pillorganizer.core.service.TenantService;

import java.io.Serializable;

@Requires(notEnv = "test")
@Singleton
public class DomainTenantResolver extends AbstractSubdomainTenantResolver implements TenantResolver {
    TenantService service;

    @Inject
    public DomainTenantResolver(HttpHostResolver httpHostResolver, TenantService service) {
        super(httpHostResolver);
        this.service = service;
    }

    @Override
    protected @NonNull Serializable resolveSubdomain(@NonNull String host) {
        return service.getTenantByHostname(host)
                .orElseThrow(() -> new TenantNotFoundException("Invalid tenant: " + host))
                .getId();
    }
}
