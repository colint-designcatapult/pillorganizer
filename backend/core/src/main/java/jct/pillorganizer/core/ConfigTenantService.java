package jct.pillorganizer.core;


import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import lombok.Getter;

import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class ConfigTenantService implements TenantService {
    @Getter
    private final Collection<TenantDetails> tenantList;
    @Getter
    private final Map<String, TenantDetails> tenantMap;
    private final Map<String, TenantDetails> hostToTenantMap;

    @Inject
    public ConfigTenantService(Collection<TenantDetails> tenantList) {
        this.tenantList = tenantList;
        this.tenantMap = tenantList.stream().collect(
                Collectors.toMap(TenantDetails::getId, tenant -> tenant)
        );
        this.hostToTenantMap = tenantList.stream().collect(
                Collectors.toMap(TenantDetails::getHostname, tenant -> tenant)
        );
    }

    public Optional<TenantDetails> getTenantDetails(String tenantId) {
        return Optional.ofNullable(tenantMap.get(tenantId));
    }

    public Optional<TenantDetails> getTenantByHostname(String hostname) {
        return Optional.ofNullable(hostToTenantMap.get(hostname));
    }
}