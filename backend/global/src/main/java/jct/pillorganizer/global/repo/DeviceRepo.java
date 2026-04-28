package jct.pillorganizer.global.repo;

import io.micronaut.core.annotation.Nullable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType;
import jct.pillorganizer.global.model.DeviceEntity;
import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.Page;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.enhanced.dynamodb.model.ScanEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class DeviceRepo extends BaseControlPlaneRepo<DeviceEntity> {
    @Inject
    public DeviceRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceEntity.class);
    }

    public Optional<DeviceEntity> findBySerialNumber(String serialNumber) {
        Key key = Key.builder()
                .partitionValue(DeviceEntity.pk(serialNumber))
                .sortValue(DeviceEntity.sk())
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }

    public Optional<DeviceEntity> findByDeviceId(String deviceId) {
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder()
                        .partitionValue(DeviceEntity.gsi2Pk(deviceId))
                        .sortValue(DeviceEntity.gsi2Sk())
                        .build()
        );

        return this.gsi2.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst();
    }

    public List<DeviceEntity> findByTenantId(String tenantId) {
        return findByTenantId(tenantId, null);
    }

    public List<DeviceEntity> findByTenantId(String tenantId, @Nullable String snFilter) {
        String skPrefix = (snFilter != null && !snFilter.isBlank())
                ? DeviceEntity.gsi1Sk(snFilter)
                : DeviceEntity.gsi1Sk("");

        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceEntity.gsi1Pk(tenantId))
                        .sortValue(skPrefix)
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    /**
     * Returns a single page of DEVICE entities via a filtered table scan.
     * Optional {@code snFilter} narrows to serial numbers beginning with the given prefix.
     */
    public PageResult<DeviceEntity> findAllPaginated(int size, @Nullable String cursor, @Nullable String snFilter) {
        Map<String, AttributeValue> exclusiveStartKey = DynamoDbCursorUtil.decode(cursor);

        Expression.Builder filterBuilder = Expression.builder()
                .expression("EntityType = :type")
                .expressionValues(Collections.singletonMap(
                        ":type", AttributeValue.builder()
                                .s(DeviceControlPlaneEntityType.DEVICE.name()).build()));

        if (snFilter != null && !snFilter.isBlank()) {
            filterBuilder
                    .expression("EntityType = :type AND begins_with(PK, :pkPrefix)")
                    .expressionValues(Map.of(
                            ":type", AttributeValue.builder().s(DeviceControlPlaneEntityType.DEVICE.name()).build(),
                            ":pkPrefix", AttributeValue.builder().s(DeviceEntity.pk(snFilter)).build()
                    ));
        }

        ScanEnhancedRequest.Builder requestBuilder = ScanEnhancedRequest.builder()
                .filterExpression(filterBuilder.build())
                .limit(size);

        if (exclusiveStartKey != null) {
            requestBuilder.exclusiveStartKey(exclusiveStartKey);
        }

        Page<DeviceEntity> page = this.table.scan(requestBuilder.build()).iterator().next();
        return new PageResult<>(page.items(), DynamoDbCursorUtil.encode(page.lastEvaluatedKey()));
    }

    public PageResult<DeviceEntity> findAllPaginated(int size, @Nullable String cursor) {
        return findAllPaginated(size, cursor, null);
    }
}

