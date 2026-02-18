package jct.pillorganizer.global.persistence.entity;

import jct.pillorganizer.global.domain.model.Device;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
public class DeviceEntity extends BaseControlPlaneEntity {

    public static DeviceEntity from(Device device) {
        DeviceEntity entity = new DeviceEntity();
        entity.setPk(pk(device.deviceId()));
        entity.setSk(skMetadata());
        entity.setGsi1Pk(gsi1Pk(device.tenantId()));
        entity.setGsi1Sk(gsi1Sk(device.deviceId()));
        entity.setGsi2Pk(gsi2Pk(device.serialNumber()));
        entity.setGsi2Sk(gsi2Sk(device.deviceId()));
        entity.setEntityType(DeviceControlPlaneEntityType.DEVICE);

        entity.setDeviceId(device.deviceId());
        entity.setTenantId(device.tenantId());
        entity.setSerialNumber(device.serialNumber());
        entity.setModelId(device.modelId());
        entity.setProvisioningStatus(device.provisioningStatus());
        entity.setVersion(device.version());
        return entity;
    }

    public static Device mapToDomain(BaseControlPlaneEntity entity) {
        return new Device(entity.getDeviceId(), entity.getTenantId(), entity.getSerialNumber(), entity.getModelId(), entity.getProvisioningStatus(),
                entity.getVersion());
    }

    public static String pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
    public static String skMetadata() {
        return "METADATA";
    }
    public static String gsi1Pk(String tenantId) {
        return "TENANT#" + tenantId;
    }
    public static String gsi1Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
    public static String gsi2Pk(String serialNumber) {
        return "SN#" + serialNumber;
    }
    public static String gsi2Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
}
