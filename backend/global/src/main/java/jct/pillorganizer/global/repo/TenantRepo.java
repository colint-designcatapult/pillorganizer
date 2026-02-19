package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.TenantEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class TenantRepo extends BaseControlPlaneRepo<TenantEntity> {
    @Inject
    public TenantRepo(DynamoDbClient standardClient) {
        super(standardClient, TenantEntity.class);
    }

    public Optional<TenantEntity> findByTenantId(String tenantId) {
        Key key = Key.builder()
                .partitionValue(TenantEntity.pk(tenantId))
                .sortValue(TenantEntity.sk())
                .build();

        return Optional.ofNullable(this.table.getItem(key));
    }

    public List<TenantEntity> findAll() {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(TenantEntity.gsi1Pk())
                        .sortValue(TenantEntity.gsi1Sk(""))
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
