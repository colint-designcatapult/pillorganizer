package jct.pillorganizer.global.persistence;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.ManufacturingRecord;
import jct.pillorganizer.global.domain.repo.ManufacturingRecordRepo;
import jct.pillorganizer.global.persistence.entity.ManufacturingRecordEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.Optional;

@Singleton
public class DynamoDbManufacturingRecordRepo extends DynamoDbDeviceControlPlaneRepo<ManufacturingRecordEntity>
        implements ManufacturingRecordRepo {
    @Inject
    public DynamoDbManufacturingRecordRepo(DynamoDbClient standardClient) {
        super(standardClient, ManufacturingRecordEntity.class);
    }

    @Override
    public Optional<ManufacturingRecord> get(String serialNumber) {
        Key key = Key.builder()
                .partitionValue(ManufacturingRecordEntity.pk(serialNumber))
                .sortValue(ManufacturingRecordEntity.skMetadata()).build();
        return Optional.ofNullable(this.table.getItem(key))
                .map(ManufacturingRecordEntity::mapToDomain);
    }

}
