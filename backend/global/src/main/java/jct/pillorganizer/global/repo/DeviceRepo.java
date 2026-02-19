package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class DeviceRepo extends BaseControlPlaneRepo<DeviceEntity> {
    @Inject
    public DeviceRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceEntity.class);
    }

    public Optional<DeviceEntity> findByDeviceId(String deviceId) {
        Key key = Key.builder()
                .partitionValue(DeviceEntity.pk(deviceId))
                .sortValue(DeviceEntity.sk())
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }

    public List<DeviceEntity> findBySerialNumber(String serialNumber) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceEntity.gsi2Pk(serialNumber))
                        .sortValue(DeviceEntity.gsi2Sk(""))
                        .build()
        );

        return this.gsi2.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    public List<DeviceEntity> findByTenantId(String tenantId) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceEntity.gsi1Pk(tenantId))
                        .sortValue(DeviceEntity.gsi1Sk(""))
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
