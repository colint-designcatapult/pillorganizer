package jct.pillorganizer.core.service;

import jct.pillorganizer.core.TenantDetails;

import java.util.Collection;
import java.util.Map;
import java.util.Optional;

public interface TenantService {
    Optional<TenantDetails> getTenantDetails(String tenantId);
    Optional<TenantDetails> getTenantByHostname(String hostname);
    Collection<TenantDetails> getTenantList();
    Map<String, TenantDetails> getTenantMap();
    Optional<TenantDetails> getCurrentTenant();
}
