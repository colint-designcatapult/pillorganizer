package jct.pillorganizer.global.persistence.entity;

import jct.pillorganizer.global.domain.model.DeviceUserAccess;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
public class DeviceUserAccessEntity extends BaseControlPlaneEntity {

    public static DeviceUserAccessEntity from(DeviceUserAccess deviceUserAccess) {
        DeviceUserAccessEntity entity = new DeviceUserAccessEntity();
        entity.setPk(pk(deviceUserAccess.deviceId()));
        entity.setSk(sk(deviceUserAccess.userId()));
        entity.setGsi1Pk(gsi1Pk(deviceUserAccess.userId()));
        entity.setGsi1Sk(gsi1Sk(deviceUserAccess.deviceId()));
        entity.setEntityType(DeviceControlPlaneEntityType.DEVICE_USER_ACCESS);

        entity.setUserId(deviceUserAccess.userId());
        entity.setDeviceId(deviceUserAccess.deviceId());
        entity.setTenantId(deviceUserAccess.tenantId());
        entity.setSerialNumber(deviceUserAccess.serialNumber());
        entity.setModelId(deviceUserAccess.modelId());
        entity.setUserName(deviceUserAccess.userName());
        entity.setPrimaryUser(deviceUserAccess.primaryUser());
        entity.setVersion(deviceUserAccess.version());
        return entity;
    }

    public static DeviceUserAccess mapToDomain(BaseControlPlaneEntity entity) {
        return new DeviceUserAccess(entity.getUserId(), entity.getDeviceId(), entity.getTenantId(), entity.getSerialNumber(), entity.getModelId(),
                entity.getUserName(), entity.getPrimaryUser(), entity.getVersion());
    }

    public static String pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
    public static String sk(String userId) {
        return "USER#" + userId;
    }
    public static String gsi1Pk(String userId) {
        return "USER#" + userId;
    }
    public static String gsi1Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
}
