package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.domain.model.ProvisioningStatus
import jct.pillorganizer.global.domain.model.exception.EntityNotFoundException
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType
import jct.pillorganizer.global.persistence.entity.DeviceUserAccessEntity
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class UserDevicesRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbUserDevicesRepo repo

    def "should get user devices view"() {
        given:
        def userId = "user-123"
        def deviceId1 = "dev-1"
        def deviceId2 = "dev-2"
        def tenantId = "tenant-1"
        
        insertUser(userId, "test@example.com", "Test User")
        
        // Device 1 Access
        insertRawRecord([
                "PK": "DEVICE#" + deviceId1,
                "SK": "USER#" + userId,
                "GSI1_PK": "USER#" + userId,
                "GSI1_SK": "DEVICE#" + deviceId1,
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.name(),
                "UserId": userId,
                "DeviceId": deviceId1,
                "TenantId": tenantId,
                "SerialNumber": "SN-1",
                "ModelId": "M-1",
                "ProvisioningStatus": ProvisioningStatus.ACTIVE.name(),
                "Version": 1
        ])

        // Device 2 Access
        insertRawRecord([
                "PK": "DEVICE#" + deviceId2,
                "SK": "USER#" + userId,
                "GSI1_PK": "USER#" + userId,
                "GSI1_SK": "DEVICE#" + deviceId2,
                "EntityType": DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.name(),
                "UserId": userId,
                "DeviceId": deviceId2,
                "TenantId": tenantId,
                "SerialNumber": "SN-2",
                "ModelId": "M-2",
                "ProvisioningStatus": ProvisioningStatus.ACTIVE.name(),
                "Version": 1
        ])

        when:
        def result = repo.get(userId)

        then:
        result.isPresent()
        with(result.get()) {
            it.user().userId() == userId
            it.devices().size() == 2
            it.devices().any { d -> d.deviceId() == deviceId1 }
            it.devices().any { d -> d.deviceId() == deviceId2 }
        }
    }

    def "should throw exception when user not found"() {
        when:
        repo.get("non-existent-user")

        then:
        thrown(EntityNotFoundException)
    }
    
    def "should return user with no devices"() {
        given:
        def userId = "user-empty"
        insertUser(userId, "empty@example.com", "Empty User")

        when:
        def result = repo.get(userId)

        then:
        result.isPresent()
        with(result.get()) {
            it.user().userId() == userId
            it.devices().isEmpty()
        }
    }
}
