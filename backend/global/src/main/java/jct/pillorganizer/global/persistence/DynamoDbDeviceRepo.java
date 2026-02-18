package jct.pillorganizer.global.persistence;


import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.repo.DeviceRepo;
import jct.pillorganizer.global.persistence.entity.DeviceEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.Optional;

@Singleton
public class DynamoDbDeviceRepo extends DynamoDbDeviceControlPlaneRepo<DeviceEntity> implements DeviceRepo {
    @Inject
    public DynamoDbDeviceRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceEntity.class);
    }

    @Override
    public Optional<Device> get(String deviceId) {
        Key key = Key.builder()
                .partitionValue(DeviceEntity.pk(deviceId))
                .sortValue(DeviceEntity.skMetadata()).build();
        return Optional.ofNullable(this.table.getItem(key))
                .map(DeviceEntity::mapToDomain);
    }

    @Override
    public Optional<Device> findBySerialNumber(String serialNumber) {
        Key key = Key.builder()
                .partitionValue(DeviceEntity.gsi2Pk(serialNumber))
                .build();

        return this.gsi2.query(b -> b.queryConditional(QueryConditional.keyEqualTo(key)))
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst()
                .map(DeviceEntity::mapToDomain);
    }
}
