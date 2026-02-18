package jct.pillorganizer.global.persistence.entity;

import jct.pillorganizer.global.domain.model.ManufacturingRecord;
import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
public class ManufacturingRecordEntity extends BaseControlPlaneEntity {

    public static ManufacturingRecordEntity from(ManufacturingRecord manufacturingRecord) {
        ManufacturingRecordEntity entity = new ManufacturingRecordEntity();
        entity.setPk(pk(manufacturingRecord.serialNumber()));
        entity.setSk(skMetadata());
        entity.setGsi2Pk(gsi2Pk(manufacturingRecord.serialNumber()));
        entity.setGsi2Sk(gsi2Sk());
        entity.setEntityType(DeviceControlPlaneEntityType.MANUFACTURING_RECORD);

        entity.setSerialNumber(manufacturingRecord.serialNumber());
        entity.setModelId(manufacturingRecord.modelId());
        entity.setBootstrapKey(manufacturingRecord.bootstrapKey());
        entity.setManufacturingDate(manufacturingRecord.manufacturingDate());
        entity.setVersion(manufacturingRecord.version());
        return entity;
    }

    public static ManufacturingRecord mapToDomain(BaseControlPlaneEntity entity) {
        return new ManufacturingRecord(entity.getSerialNumber(), entity.getModelId(), entity.getBootstrapKey(), entity.getManufacturingDate(),
                entity.getVersion());
    }

    public static String pk(String serialNumber) {
        return "SN#" + serialNumber;
    }
    public static String skMetadata() {
        return "METADATA";
    }

    public static String gsi2Pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String gsi2Sk() {
        return "METADATA";
    }
}
