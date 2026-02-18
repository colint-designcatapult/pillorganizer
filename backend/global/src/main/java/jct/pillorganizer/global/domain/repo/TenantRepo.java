package jct.pillorganizer.global.domain.repo;

import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.Tenant;
import software.amazon.awssdk.enhanced.dynamodb.model.Page;

import java.util.List;
import java.util.Optional;

public interface TenantRepo {
    Optional<Tenant> get(String tenantId);
    List<Tenant> findAll();
}
