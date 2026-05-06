package jct.pillorganizer.global.repo

// @relation(CTRL-REQ-22, scope=file)
// @relation(CTRL-REQ-23, scope=file)
// @relation(UN-601, scope=file)
// @relation(UN-602, scope=file)
// @relation(SYS-REQ-44, scope=file)
// @relation(SYS-REQ-47, scope=file)
import com.github.ksuid.Ksuid
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceClaimEntity
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceClaimRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DeviceClaimRepo repo

    def "should get DeviceClaim by serial number and claim id"() {
        given:
        def serialNumber = "SN-123"
        def claimToken = Ksuid.newKsuid().toString()
        def claimId = Ksuid.newKsuid().toString()
        def userId = "user-1"
        def deviceId = "device-1"

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId("tenant-1")
                .deviceId(deviceId)
                .thingName("tenant-1-" + serialNumber + "-" + deviceId)
                .build()

        repo.save(claim)

        when:
        def found = repo.findBySerialNumberAndClaimId(serialNumber, claimId)

        then:
        found.isPresent()
        found.get().serialNumber == serialNumber
        found.get().claimToken == claimToken
        found.get().claimId == claimId
        found.get().userId == userId
    }

    def "should find all DeviceClaims by serial number"() {
        given:
        def serialNumber1 = "SN-123"
        def serialNumber2 = "SN-456"
        def userId = "user-1"

        this.insertDeviceClaim(serialNumber1, "C1", userId)
        this.insertDeviceClaim(serialNumber1, "C2", userId)
        this.insertDeviceClaim(serialNumber2, "C3", userId)

        when:
        def claims = repo.findAllBySerialNumber(serialNumber1)

        then:
        claims.size() == 2
        claims.every { it.serialNumber == serialNumber1 }
        claims.any { it.claimToken == "C1" }
        claims.any { it.claimToken == "C2" }
    }

    def "should find all DeviceClaims by user id"() {
        given:
        def userId1 = "user-1"
        def userId2 = "user-2"
        def serialNumber = "SN-123"

        this.insertDeviceClaim(serialNumber, "C1", userId1)
        this.insertDeviceClaim(serialNumber, "C2", userId1)
        this.insertDeviceClaim(serialNumber, "C3", userId2)

        when:
        def claims = repo.findAllByUserId(userId1)

        then:
        claims.size() == 2
        claims.every { it.userId == userId1 }
        claims.any { it.claimToken == "C1" }
        claims.any { it.claimToken == "C2" }
    }

    def "should save DeviceClaim"() {
        given:
        def serialNumber = "SN-NEW"
        def claimToken = "CLAIM-NEW"
        def claimId = "CLAIM-ID-NEW"
        def userId = "user-new"
        def tenantId = "tenant-new"
        def deviceId = "device-new"

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .thingName("thing-new")
                .build()

        when:
        repo.save(claim)

        then:
        def savedClaim = repo.findBySerialNumberAndClaimId(serialNumber, claimId)
        savedClaim.isPresent()
        savedClaim.get().serialNumber == serialNumber
        savedClaim.get().claimToken == claimToken
        savedClaim.get().claimId == claimId
        savedClaim.get().userId == userId
        savedClaim.get().tenantId == tenantId
        savedClaim.get().base.entityType == DeviceControlPlaneEntityType.DEVICE_CLAIM
    }

    def "should fail to find non-existent DeviceClaim"() {
        when:
        def claim = repo.findBySerialNumberAndClaimId("SN-NONE", "CLAIM-NONE-ID")

        then:
        claim.isEmpty()
    }
}
