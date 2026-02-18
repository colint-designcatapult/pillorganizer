package jct.pillorganizer.global.persistence;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.Tenant;
import jct.pillorganizer.global.domain.repo.TenantRepo;
import jct.pillorganizer.global.persistence.entity.TenantEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.Page;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;

@Singleton
public class DynamoDbTenantRepo extends DynamoDbDeviceControlPlaneRepo<TenantEntity> implements TenantRepo {
    @Inject
    public DynamoDbTenantRepo(DynamoDbClient standardClient) {
        super(standardClient, TenantEntity.class);
    }

    @Override
    public Optional<Tenant> get(String tenantId) {
        Key key = Key.builder()
                .partitionValue(TenantEntity.pk(tenantId))
                .sortValue(TenantEntity.skMetadata()).build();
        return Optional.ofNullable(this.table.getItem(key))
                .map(TenantEntity::mapToDomain);

    }

    @Override
    public List<Tenant> findAll() {
        Key key = Key.builder()
                .partitionValue(TenantEntity.gsi1Pk())
                .build();
        return this.gsi1.query(b -> b.queryConditional(QueryConditional.keyEqualTo(key)))
                .stream()
                .flatMap(page -> page.items().stream())
                .map(TenantEntity::mapToDomain)
                .toList();
    }
}
