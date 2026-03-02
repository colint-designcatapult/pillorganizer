package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class DeviceTenantMappingRepo extends BaseControlPlaneRepo<DeviceTenantMappingEntity> {
    @Inject
    public DeviceTenantMappingRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceTenantMappingEntity.class);
    }

    public Optional<DeviceTenantMappingEntity> findBySerialNumber(String serialNumber) {
        Key key = Key.builder()
                .partitionValue(DeviceTenantMappingEntity.pk(serialNumber))
                .sortValue(DeviceTenantMappingEntity.sk())
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }

    public List<DeviceTenantMappingEntity> findAllByTenantId(String tenantId) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceTenantMappingEntity.gsi1Pk(tenantId))
                        .sortValue(DeviceTenantMappingEntity.gsi1Sk(""))
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
