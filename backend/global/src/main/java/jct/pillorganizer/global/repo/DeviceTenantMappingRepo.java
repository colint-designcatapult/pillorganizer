package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;
import io.micronaut.core.annotation.Nullable;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.Page;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.util.List;
import java.util.Map;
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
        return findAllByTenantId(tenantId, null);
    }

    public List<DeviceTenantMappingEntity> findAllByTenantId(String tenantId, @Nullable String snFilter) {
        String skPrefix = (snFilter != null && !snFilter.isBlank())
                ? DeviceTenantMappingEntity.gsi1Sk(snFilter)
                : DeviceTenantMappingEntity.gsi1Sk("");

        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceTenantMappingEntity.gsi1Pk(tenantId))
                        .sortValue(skPrefix)
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    /**
     * Returns a single paginated page of mappings for the given tenant via GSI1.
     * Optional {@code snFilter} narrows to serial numbers beginning with the given prefix.
     */
    public PageResult<DeviceTenantMappingEntity> findAllByTenantIdPaginated(
            String tenantId, int size, @Nullable String cursor, @Nullable String snFilter) {
        Map<String, AttributeValue> exclusiveStartKey = DynamoDbCursorUtil.decode(cursor);

        String skPrefix = (snFilter != null && !snFilter.isBlank())
                ? DeviceTenantMappingEntity.gsi1Sk(snFilter)
                : DeviceTenantMappingEntity.gsi1Sk("");

        QueryEnhancedRequest.Builder requestBuilder = QueryEnhancedRequest.builder()
                .queryConditional(QueryConditional.sortBeginsWith(
                        Key.builder()
                                .partitionValue(DeviceTenantMappingEntity.gsi1Pk(tenantId))
                                .sortValue(skPrefix)
                                .build()))
                .limit(size);

        if (exclusiveStartKey != null) {
            requestBuilder.exclusiveStartKey(exclusiveStartKey);
        }

        Page<DeviceTenantMappingEntity> page = this.gsi1.query(requestBuilder.build()).iterator().next();
        return new PageResult<>(page.items(), DynamoDbCursorUtil.encode(page.lastEvaluatedKey()));
    }
}

