package jct.pillorganizer.global.persistence

import jct.pillorganizer.global.model.DeviceClaimEntity
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.model.DeviceTenantMappingEntity
import jct.pillorganizer.global.model.UserEntity

abstract class BaseDeviceControlPlaneSpec extends BaseDynamoDbSpec {

    @Override
    protected String tableName() {
        return "DeviceControlPlane"
    }

    void insertDevice(String tenantId, String serialNumber, String deviceId = "device-1") {
        insertRawRecord([
                "PK": DeviceEntity.pk(serialNumber),
                "SK": DeviceEntity.sk(),
                "GSI1_PK": DeviceEntity.gsi1Pk(tenantId),
                "GSI1_SK": DeviceEntity.gsi1Sk(serialNumber),
                "GSI2_PK": DeviceEntity.gsi2Pk(deviceId),
                "GSI2_SK": DeviceEntity.gsi2Sk(),
                "EntityType": DeviceControlPlaneEntityType.DEVICE.toString(),
                "TenantId": tenantId,
                "SerialNumber": serialNumber,
                "DeviceId": deviceId,
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

    void insertDeviceClaim(String serialNumber, String claimId, String userId, String tenantId = "tenant-1") {
        insertRawRecord([
                "PK": DeviceClaimEntity.pk(serialNumber),
                "SK": DeviceClaimEntity.sk(claimId),
                "GSI1_PK": DeviceClaimEntity.gsi1Pk(userId),
                "GSI1_SK": DeviceClaimEntity.gsi1Sk(claimId),
                "EntityType": DeviceControlPlaneEntityType.DEVICE_CLAIM.toString(),
                "SerialNumber": serialNumber,
                "ClaimToken": claimId,
                "UserId": userId,
                "TenantId": tenantId,
                "Version": 1
        ])
    }

    void insertDeviceTenantMapping(String serialNumber, String tenantId) {
        insertRawRecord([
                "PK": DeviceTenantMappingEntity.pk(serialNumber),
                "SK": DeviceTenantMappingEntity.sk(),
                "GSI1_PK": DeviceTenantMappingEntity.gsi1Pk(tenantId),
                "GSI1_SK": DeviceTenantMappingEntity.gsi1Sk(serialNumber),
                "EntityType": DeviceControlPlaneEntityType.DEVICE_TENANT_MAPPING.toString(),
                "SerialNumber": serialNumber,
                "TenantId": tenantId,
                "Version": 1
        ])
    }

}
