package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class DeviceClaimRepo extends BaseControlPlaneRepo<DeviceClaimEntity> {
    @Inject
    public DeviceClaimRepo(DynamoDbClient standardClient) {
        super(standardClient, DeviceClaimEntity.class);
    }

    public Optional<DeviceClaimEntity> findBySerialNumberAndClaimId(String serialNumber, String claimId) {
        Key key = Key.builder()
                .partitionValue(DeviceClaimEntity.pk(serialNumber))
                .sortValue(DeviceClaimEntity.sk(claimId))
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }

    public List<DeviceClaimEntity> findAllBySerialNumber(String serialNumber) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceClaimEntity.pk(serialNumber))
                        .sortValue(DeviceClaimEntity.sk(""))
                        .build()
        );

        return this.table.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }

    public List<DeviceClaimEntity> findAllByUserId(String userId) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(DeviceClaimEntity.gsi1Pk(userId))
                        .sortValue(DeviceClaimEntity.gsi1Sk(""))
                        .build()
        );

        return this.gsi1.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
