package jct.pillorganizer.global.persistence

import jct.pillorganizer.global.domain.model.ProvisioningStatus
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType
import jct.pillorganizer.global.persistence.entity.DeviceEntity
import jct.pillorganizer.global.persistence.entity.DeviceUserAccessEntity
import jct.pillorganizer.global.persistence.entity.ManufacturingRecordEntity
import jct.pillorganizer.global.persistence.entity.TenantEntity

abstract class BaseDeviceControlPlaneSpec extends BaseDynamoDbSpec {

    @Override
    protected String tableName() {
        return "DeviceControlPlane"
    }

    void insertTenant(String tenantId, String name = "Test Tenant", String description = "Test Description",
                      String apiBase = "https://api.test.com") {
        insertRawRecord([
                "PK": TenantEntity.pk(tenantId),
                "SK": TenantEntity.skMetadata(),
                "GSI1_PK": TenantEntity.gsi1Pk(),
                "GSI1_SK": TenantEntity.gsi1Sk(tenantId),
                "EntityType": DeviceControlPlaneEntityType.TENANT.toString(),
                "TenantId": tenantId,
                "TenantName": name,
                "TenantDescription": description,
                "TenantApiBase": apiBase,
                "Version": 1
        ])
    }

    void insertManufacturingRecord(String serialNumber, String modelId = "MODEL-X", String bootstrapKey = "key-123",
                                   String manufacturingDate = "2023-01-01") {
        insertRawRecord([
                "PK": ManufacturingRecordEntity.pk(serialNumber),
                "SK": ManufacturingRecordEntity.skMetadata(),
                "GSI2_PK": ManufacturingRecordEntity.gsi2Pk(serialNumber),
                "GSI2_SK": ManufacturingRecordEntity.gsi2Sk(),
                "EntityType": DeviceControlPlaneEntityType.MANUFACTURING_RECORD.toString(),
                "SerialNumber": serialNumber,
                "ModelId": modelId,
                "BootstrapKey": bootstrapKey,
                "ManufacturingDate": manufacturingDate,
                "Version": 1
        ])
    }

    void insertDevice(String deviceId, String tenantId, String serialNumber, String modelId = "MODEL-X",
                      ProvisioningStatus status = ProvisioningStatus.ACTIVE) {
        insertRawRecord([
                "PK": DeviceEntity.pk(deviceId),
                "SK": DeviceEntity.skMetadata(),
                "GSI1_PK": DeviceEntity.gsi1Pk(tenantId),
                "GSI1_SK": DeviceEntity.gsi1Sk(deviceId),
                "GSI2_PK": "SN#" + serialNumber,
                "GSI2_SK": "DEVICE#" + deviceId,
                "EntityType": DeviceControlPlaneEntityType.DEVICE.toString(),
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "SerialNumber": serialNumber,
                "ModelId": modelId,
                "ProvisioningStatus": status.toString(),
                "Version": 1
        ])
    }

    void insertUser(String userId, String email = "test@example.com", String name = "Test User") {
        insertRawRecord([
                "PK": "USER#" + userId,
                "SK": "METADATA",
                "GSI1_PK": "USER#" + userId,
                "GSI1_SK": "METADATA",
                "EntityType": DeviceControlPlaneEntityType.USER.toString(),
                "UserId": userId,
                "Email": email,
                "UserName": name,
                "Version": 1
        ])
    }

    void insertDeviceUserAccess(String deviceId, String userId, String tenantId, String serialNumber,
                                String modelId = "MODEL-X", String userName = "Test User", boolean isPrimary = false) {
        insertRawRecord([
                "PK": DeviceUserAccessEntity.pk(deviceId),
                "SK": DeviceUserAccessEntity.sk(userId),
                "GSI1_PK": DeviceUserAccessEntity.gsi1Pk(userId),
                "GSI1_SK": DeviceUserAccessEntity.gsi1Sk(deviceId),
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.toString(),
                "UserId": userId,
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "SerialNumber": serialNumber,
                "ModelId": modelId,
                "UserName": userName,
                "PrimaryUser": isPrimary,
                "Version": 1
        ])
    }
}
