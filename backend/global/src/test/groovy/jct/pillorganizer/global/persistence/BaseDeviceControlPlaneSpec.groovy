package jct.pillorganizer.global.persistence

import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.model.DeviceUserLinkEntity
import jct.pillorganizer.global.model.ProvisioningStatus
import jct.pillorganizer.global.model.TenantEntity
import jct.pillorganizer.global.model.UserEntity

abstract class BaseDeviceControlPlaneSpec extends BaseDynamoDbSpec {

    @Override
    protected String tableName() {
        return "DeviceControlPlane"
    }


    void insertTenant(String tenantId, String name = "Test Tenant", String apiBase = "https://api.test.com") {
        insertRawRecord([
                "PK": TenantEntity.pk(tenantId),
                "SK": TenantEntity.sk(),
                "GSI1_PK": TenantEntity.gsi1Pk(),
                "GSI1_SK": TenantEntity.gsi1Sk(tenantId),
                "EntityType": DeviceControlPlaneEntityType.TENANT.toString(),
                "TenantId": tenantId,
                "TenantName": name,
                "TenantApiBase": apiBase,
                "Version": 1
        ])
    }

    void insertDevice(String deviceId, String tenantId, String serialNumber, String modelId = "MODEL-X",
                      ProvisioningStatus status = ProvisioningStatus.ACTIVE) {
        insertRawRecord([
                "PK": DeviceEntity.pk(deviceId),
                "SK": DeviceEntity.sk(),
                "GSI1_PK": DeviceEntity.gsi1Pk(tenantId),
                "GSI1_SK": DeviceEntity.gsi1Sk(deviceId),
                "GSI2_PK": DeviceEntity.gsi2Pk(serialNumber),
                "GSI2_SK": DeviceEntity.gsi2Sk(deviceId),
                "EntityType": DeviceControlPlaneEntityType.DEVICE.toString(),
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "SerialNumber": serialNumber,
                "ModelId": modelId,
                "ProvisioningStatus": status.toString(),
                "Version": 1
        ])
    }

    void insertUser(String userId, String name = "Test User", String sub = "sub-1") {
        insertRawRecord([
                "PK": UserEntity.pk(userId),
                "SK": UserEntity.sk(sub),
                "GSI1_PK": UserEntity.gsi1Pk(),
                "GSI1_SK": UserEntity.gsi1Sk(userId),
                "GSI2_PK": UserEntity.gsi2Pk(sub),
                "GSI2_SK": UserEntity.gsi2Sk(),
                "EntityType": DeviceControlPlaneEntityType.USER.toString(),
                "UserId": userId,
                "UserName": name,
                "UserSub": sub,
                "Version": 1
        ])
    }

    void insertDeviceUserLink(String deviceId, String userId, String tenantId, String modelId = "MODEL-X", boolean isPrimary = false) {
        insertRawRecord([
                "PK": DeviceUserLinkEntity.pk(userId),
                "SK": DeviceUserLinkEntity.sk(deviceId),
                "GSI1_PK": DeviceUserLinkEntity.gsi1Pk(deviceId),
                "GSI1_SK": DeviceUserLinkEntity.gsi1Sk(userId),
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_LINK.toString(),
                "UserId": userId,
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "ModelId": modelId,
                "PrimaryUser": isPrimary,
                "Version": 1
        ])
    }
}
