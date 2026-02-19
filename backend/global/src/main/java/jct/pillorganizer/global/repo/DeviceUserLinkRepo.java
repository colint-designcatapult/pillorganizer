package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceUserLinkEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class DeviceUserLinkRepo extends BaseControlPlaneRepo<DeviceUserLinkEntity> {
    @Inject
    public DeviceUserLinkRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceUserLinkEntity.class);
    }

    public Optional<DeviceUserLinkEntity> findByDeviceIdAndUserId(String deviceId, String userId) {
        Key key = Key.builder()
                .partitionValue(DeviceUserLinkEntity.pk(deviceId))
                .sortValue(DeviceUserLinkEntity.sk(userId))
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }

    public List<DeviceUserLinkEntity> findByDeviceId(String deviceId) {
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder()
                        .partitionValue(DeviceUserLinkEntity.pk(deviceId))
                        .build()
        );

        return this.table.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    public List<DeviceUserLinkEntity> findByUserId(String userId) {
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder()
                        .partitionValue(DeviceUserLinkEntity.gsi1Pk(userId))
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
