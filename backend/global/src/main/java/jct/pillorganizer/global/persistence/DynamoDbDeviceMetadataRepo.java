package jct.pillorganizer.global.persistence;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.ManufacturingRecord;
import jct.pillorganizer.global.domain.model.view.DeviceMetadataView;
import jct.pillorganizer.global.domain.repo.cqrs.DeviceMetadataRepo;
import jct.pillorganizer.global.persistence.entity.BaseControlPlaneEntity;
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType;
import jct.pillorganizer.global.persistence.entity.DeviceEntity;
import jct.pillorganizer.global.persistence.entity.ManufacturingRecordEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.Optional;

@Singleton
public class DynamoDbDeviceMetadataRepo extends DynamoDbDeviceControlPlaneRepo<BaseControlPlaneEntity>
        implements DeviceMetadataRepo {

    @Inject
    protected DynamoDbDeviceMetadataRepo(DynamoDbClient standardClient) {
        super(standardClient, BaseControlPlaneEntity.class);
    }

    @Override
    public Optional<DeviceMetadataView> findBySerialNumber(String serialNumber) {
        Key key = Key.builder()
                .partitionValue(ManufacturingRecordEntity.gsi2Pk(serialNumber))
                .build();

        var result = this.gsi2.query(QueryConditional.keyEqualTo(key));

        ManufacturingRecord manufacturingRecord = null;
        Device device = null;
        for(var page : result) {
            for(var item : page.items()) {
                if(DeviceControlPlaneEntityType.DEVICE.equals(item.getEntityType())) {
                    device = DeviceEntity.mapToDomain(item);
                } else if(DeviceControlPlaneEntityType.MANUFACTURING_RECORD.equals(item.getEntityType())) {
                    manufacturingRecord = ManufacturingRecordEntity.mapToDomain(item);
                }
            }
        }

        if (device != null && manufacturingRecord == null) {
            throw new IllegalStateException("Device record has no manufacturing record");
        } else if(manufacturingRecord == null) {
            return Optional.empty();
        } else {
            return Optional.of(new DeviceMetadataView(manufacturingRecord, device));
        }
    }
}
