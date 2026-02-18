package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.domain.model.ProvisioningStatus
import jct.pillorganizer.global.domain.model.exception.EntityNotFoundException
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceUsersRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbDeviceUsersRepo repo

    def "should get device users view"() {
        given:
        def deviceId = "dev-123"
        def userId1 = "user-1"
        def userId2 = "user-2"
        def tenantId = "tenant-1"
        
        insertDevice(deviceId, tenantId, "SN-1", "M-1", ProvisioningStatus.ACTIVE)

        // User 1 Access
        insertRawRecord([
                "PK": "DEVICE#" + deviceId,
                "SK": "USER#" + userId1,
                "GSI1_PK": "USER#" + userId1,
                "GSI1_SK": "DEVICE#" + deviceId,
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.toString(),
                "UserId": userId1,
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "SerialNumber": "SN-1",
                "ModelId": "M-1",
                "UserName": "User 1",
                "PrimaryUser": true,
                "Version": 1
        ])

        // User 2 Access
        insertRawRecord([
                "PK": "DEVICE#" + deviceId,
                "SK": "USER#" + userId2,
                "GSI1_PK": "USER#" + userId2,
                "GSI1_SK": "DEVICE#" + deviceId,
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.toString(),
                "UserId": userId2,
                "DeviceId": deviceId,
                "TenantId": tenantId,
                "SerialNumber": "SN-1",
                "ModelId": "M-1",
                "UserName": "User 2",
                "PrimaryUser": false,
                "Version": 1
        ])

        when:
        def result = repo.get(deviceId)

        then:
        result.isPresent()
        with(result.get()) {
            it.device().deviceId() == deviceId
            it.users().size() == 2
            it.users().any { u -> u.userId() == userId1 && u.primaryUser() }
            it.users().any { u -> u.userId() == userId2 && !u.primaryUser() }
        }
    }

    def "should throw exception when device not found"() {
        when:
        repo.get("non-existent-device")

        then:
        thrown(EntityNotFoundException)
    }
    
    def "should return device with no users"() {
        given:
        def deviceId = "dev-empty"
        def tenantId = "tenant-1"
        
        insertDevice(deviceId, tenantId, "SN-EMPTY", "M-EMPTY", ProvisioningStatus.ACTIVE)

        when:
        def result = repo.get(deviceId)

        then:
        result.isPresent()
        with(result.get()) {
            it.device().deviceId() == deviceId
            it.users().isEmpty()
        }
    }
}
