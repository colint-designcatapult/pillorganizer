package jct.pillorganizer.tenant.service;

import jct.pillorganizer.core.TenantDetails;

import java.util.Optional;

public interface TenantService {
    Optional<TenantDetails> getCurrentTenant();
}
