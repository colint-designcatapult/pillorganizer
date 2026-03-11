package jct.pillorganizer.global.service

import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.service.SecureRandomService
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.model.BaseControlPlaneEntity
import jct.pillorganizer.global.model.DeviceClaimEntity
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.DeviceClaimRepo
import jct.pillorganizer.global.repo.DeviceRepo
import software.amazon.awssdk.services.iot.IotClient
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimResponse
import software.amazon.awssdk.services.iot.model.KeyPair
import spock.lang.Subject

import jakarta.inject.Inject

import jct.pillorganizer.global.exception.DeviceAccessException
import reactor.core.publisher.Mono

import java.time.Duration
import java.time.Instant

class DeviceProvisionServiceSpec extends BaseIntegrationSpec {

    IotClient iotClient = Mock()
    TenantMessageService messageService = Mock()
    DeviceService deviceService = Mock()
    TenantService tenantService = Mock()
    UserService userService = Mock()

    @Inject
    DeviceRepo deviceRepo

    @Inject
    DeviceClaimRepo deviceClaimRepo

    @Inject
    SecureRandomService secureRandomService

    @Inject
    KsuidService ksuidService

    @Subject
    DeviceProvisionService deviceProvisionService

    def setup() {
        deviceProvisionService = new DeviceProvisionService(
                iotClient,
                deviceClaimRepo,
                deviceRepo,
                deviceService,
                messageService,
                userService,
                secureRandomService,
                ksuidService,
                tenantService
        )
    }

    def "should generate provisioning claim"() {
        given:
        def serialNumber = "SN-123"
        def userId = "user-123"
        def tenantId = "tenant-1"

        def mockResponse = CreateProvisioningClaimResponse.builder()
                .certificatePem("cert-pem")
                .keyPair(KeyPair.builder().privateKey("private-key").build())
                .expiration(Instant.now().plusSeconds(3600))
                .build()

        and:
        iotClient.createProvisioningClaim(_) >> mockResponse
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.of(TenantDetails.TEST_TENANT)
        messageService.getDeviceClaimEligibility(tenantId, _, serialNumber) >> Mono.just(new DeviceClaimEligibilityDto(true, false))

        when:
        def result = deviceProvisionService.generateProvisioningClaim(serialNumber, userId, null)
                .block(Duration.ofSeconds(10))

        then:
        result.tenantId() == tenantId
        result.tenantApiBase() == TenantDetails.TEST_TENANT.apiBase
        result.deviceId() != null
        result.claimId() != null
        result.claimToken() != null

        and:
        def savedClaim = deviceClaimRepo.findBySerialNumberAndClaimId(serialNumber, result.claimId())
        savedClaim.isPresent()
        savedClaim.get().userId == userId
        savedClaim.get().tenantId == tenantId
    }

    def "should fail to generate provisioning claim with a non-existent requested device ID"() {
        given:
        def serialNumber = "SN-REQ-123"
        def userId = "user-123"
        def tenantId = "tenant-1"
        def requestedDeviceId = "invalid-device-123"

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.of(TenantDetails.TEST_TENANT)
        messageService.getDeviceClaimEligibility(tenantId, requestedDeviceId, serialNumber) >> Mono.just(new DeviceClaimEligibilityDto(true, false))

        when:
        deviceProvisionService.generateProvisioningClaim(serialNumber, userId, requestedDeviceId)
                .block(Duration.ofSeconds(10))

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Not eligible to claim device"
    }

    def "should generate provisioning claim with an existing requested device ID"() {
        given:
        def serialNumber = "SN-REQ-456"
        def userId = "user-123"
        def tenantId = "tenant-1"
        def requestedDeviceId = "valid-device-123"

        def mockResponse = CreateProvisioningClaimResponse.builder()
                .certificatePem("cert-pem")
                .keyPair(KeyPair.builder().privateKey("private-key").build())
                .expiration(Instant.now().plusSeconds(3600))
                .build()

        and:
        iotClient.createProvisioningClaim(_) >> mockResponse
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.of(TenantDetails.TEST_TENANT)
        messageService.getDeviceClaimEligibility(tenantId, requestedDeviceId, serialNumber) >> Mono.just(new DeviceClaimEligibilityDto(true, true))

        when:
        def result = deviceProvisionService.generateProvisioningClaim(serialNumber, userId, requestedDeviceId)
                .block(Duration.ofSeconds(10))

        then:
        result.tenantId() == tenantId
        result.tenantApiBase() == TenantDetails.TEST_TENANT.apiBase
        result.deviceId() == requestedDeviceId
        result.claimId() != null
    }

    def "should fail to generate provisioning claim if user is not eligible"() {
        given:
        def serialNumber = "SN-REQ-789"
        def userId = "user-123"
        def tenantId = "tenant-1"

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.of(TenantDetails.TEST_TENANT)
        messageService.getDeviceClaimEligibility(tenantId, _, serialNumber) >> Mono.just(new DeviceClaimEligibilityDto(false, false))

        when:
        deviceProvisionService.generateProvisioningClaim(serialNumber, userId, null)
                .block(Duration.ofSeconds(10))

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Not eligible to claim device"
    }

    def "should throw IllegalStateException when generating claim for unregistered tenant"() {
        given:
        def serialNumber = "SN-UNREG"
        def userId = "user-123"
        def tenantId = "tenant-unregistered"

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.empty()

        when:
        deviceProvisionService.generateProvisioningClaim(serialNumber, userId, null)
                .block(Duration.ofSeconds(10))

        then:
        def e = thrown(IllegalStateException)
        e.message == "Device assigned to unregistered tenant: " + tenantId
    }

    def "should provision device successfully"() {
        given:
        def serialNumber = "SN-456"
        def claimToken = "token-456"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-456"
        def tenantId = "tenant-456"
        def userName = "Test User"
        def email = "test@example.com"
        def deviceId = ksuidService.generateKsuid()

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .thingName(tenantId + "-" + serialNumber + "-" + deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        userService.get(userId) >> Optional.of(UserEntity.builder()
                .userId(userId)
                .userName(userName)
                .email(email)
                .build())
        deviceService.lookupTenant(serialNumber) >> tenantId

        when:
        def result = deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        result != null
        result.serialNumber == serialNumber
        result.tenantId == tenantId
        result.deviceId == deviceId

        and:
        def savedDevice = deviceRepo.findBySerialNumber(serialNumber)
        savedDevice.isPresent()
        savedDevice.get().deviceId == deviceId

        and:
        def updatedClaim = deviceClaimRepo.findBySerialNumberAndClaimId(serialNumber, claimId)
        updatedClaim.isPresent()
        updatedClaim.get().deviceId == deviceId

        and:
        1 * messageService.grantUser({ it.userId == userId && it.userName == userName })
        1 * messageService.provisionDevice({ it.deviceId != null && it.serialNo == serialNumber })
    }

    def "should provision device successfully when updating existing device"() {
        given:
        def serialNumber = "SN-UPDATE-456-3"
        def claimToken = "token-update-456-3"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-update-456-3"
        def tenantId = "tenant-update-456-3"
        def userName = "Test User Update 3"
        def email = "test-update3@example.com"
        def newDeviceId = ksuidService.generateKsuid()

        def oldDeviceId = "old-device-id"
        def oldTenantId = "tenant-000"

        // Insert existing device
        def existingDevice = DeviceEntity.builder()
                .base(DeviceEntity.buildBase(serialNumber, oldTenantId, oldDeviceId))
                .serialNumber(serialNumber)
                .deviceId(oldDeviceId)
                .tenantId(oldTenantId)
                .claimId("old-claim")
                .thingName("old-thing")
                .build()
        deviceRepo.save(existingDevice)

        // Insert new claim
        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, newDeviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(newDeviceId)
                .thingName(tenantId + "-" + serialNumber + "-" + newDeviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        userService.get(userId) >> Optional.of(UserEntity.builder()
                .userId(userId)
                .userName(userName)
                .email(email)
                .build())
        deviceService.lookupTenant(serialNumber) >> tenantId

        when:
        def result = deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        result != null
        result.serialNumber == serialNumber
        result.tenantId == tenantId
        result.deviceId == newDeviceId

        and:
        def savedDevice = deviceRepo.findBySerialNumber(serialNumber)
        savedDevice.isPresent()
        savedDevice.get().deviceId == newDeviceId
        savedDevice.get().tenantId == tenantId

        // Ensure GSI keys are properly updated
        savedDevice.get().base.gsi1Pk == DeviceEntity.gsi1Pk(tenantId)
        savedDevice.get().base.gsi2Pk == DeviceEntity.gsi2Pk(newDeviceId)

        and:
        1 * messageService.grantUser({ it.userId == userId && it.userName == userName })
        1 * messageService.provisionDevice({ it.deviceId == newDeviceId && it.serialNo == serialNumber })
    }

    def "should fail to provision when claimed tenant does not match assigned tenant"() {
        given:
        def serialNumber = "SN-TENANT-MISMATCH"
        def claimToken = "token-tenant-mismatch"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-mismatch"
        def originalTenantId = "tenant-mismatch-old"
        def newTenantId = "tenant-mismatch-new"
        def deviceId = ksuidService.generateKsuid()

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(originalTenantId) // Claim created for original tenant
                .deviceId(deviceId)
                .thingName(originalTenantId + "-" + serialNumber + "-" + deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        // By the time provisioning happens, lookup says it belongs to a new tenant
        deviceService.lookupTenant(serialNumber) >> newTenantId

        when:
        deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        def e = thrown(IllegalStateException)
        e.message == "Invalid claim token"
    }

    def "should fail to provision when user entity no longer exists"() {
        given:
        def serialNumber = "SN-USER-MISSING"
        def claimToken = "token-user-missing"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-deleted"
        def tenantId = "tenant-user-missing"
        def deviceId = ksuidService.generateKsuid()

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        // User lookup returns empty
        userService.get(userId) >> Optional.empty()

        when:
        deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        def e = thrown(IllegalStateException)
        e.message == "User not found: %s" + userId
    }

    def "should throw RuntimeException if messageService.grantUser throws IOException"() {
        given:
        def serialNumber = "SN-FAIL-GRANT"
        def claimToken = "token-fail-grant"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-fail-grant"
        def tenantId = "tenant-fail-grant"
        def deviceId = ksuidService.generateKsuid()

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        userService.get(userId) >> Optional.of(UserEntity.builder()
                .userId(userId)
                .userName("Test User")
                .email("test@example.com")
                .build())
        messageService.grantUser(_) >> { throw new IOException("Network failure") }

        when:
        deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        def e = thrown(RuntimeException)
        e.cause instanceof IOException
    }

    def "should throw RuntimeException if messageService.provisionDevice throws IOException"() {
        given:
        def serialNumber = "SN-FAIL-PROVISION"
        def claimToken = "token-fail-provision"
        def claimId = ksuidService.generateKsuid()
        def userId = "user-fail-provision"
        def tenantId = "tenant-fail-provision"
        def deviceId = ksuidService.generateKsuid()

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        deviceService.lookupTenant(serialNumber) >> tenantId
        userService.get(userId) >> Optional.of(UserEntity.builder()
                .userId(userId)
                .userName("Test User")
                .email("test@example.com")
                .build())
        messageService.grantUser(_) >> { /* Success */ }
        messageService.provisionDevice(_) >> { throw new IOException("Network failure") }

        when:
        deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        def e = thrown(RuntimeException)
        e.cause instanceof IOException
    }

    def "should return empty when claim not found"() {
        given:
        def serialNumber = "SN-UNKNOWN"
        def claimToken = "invalid-token"
        def claimId = "invalid-id"

        when:
        def result = deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Claim not found"
        0 * messageService._
    }

    def "should return certificate when claim is valid"() {
        given:
        def serialNumber = "SN-CERT-3"
        def claimToken = "token-cert-3"
        def claimId = "claim-cert-3"
        def userId = "user-cert-3"
        def tenantId = "tenant-cert-3"
        def deviceId = "device-cert-3"

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        def mockResponse = CreateProvisioningClaimResponse.builder()
                .certificatePem("cert-pem")
                .keyPair(KeyPair.builder().privateKey("private-key").build())
                .expiration(Instant.now().plusSeconds(3600))
                .build()
        iotClient.createProvisioningClaim(_) >> mockResponse

        when:
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimId, claimToken)

        then:
        result != null
        result.certificatePem() == "cert-pem"
        result.privateKey() == "private-key"
    }

    def "should return empty when claim not found for certificate"() {
        given:
        def serialNumber = "SN-UNKNOWN"
        def claimToken = "invalid-token"
        def claimId = "invalid-id"

        when:
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimId, claimToken)

        then:
        def e = thrown(DeviceAccessException)
        e.message == "No claim found"
    }

    def "should return empty when claim is expired"() {
        given:
        def serialNumber = "SN-EXPIRED-3"
        def claimToken = "token-expired-3"
        def claimId = "claim-expired-3"
        def userId = "user-expired-3"
        def tenantId = "tenant-expired-3"
        def deviceId = "device-expired-3"

        def base = BaseControlPlaneEntity.builder()
                .pk(DeviceClaimEntity.pk(serialNumber))
                .sk(DeviceClaimEntity.sk(claimId))
                .entityType(DeviceControlPlaneEntityType.DEVICE_CLAIM)
                .gsi1Pk(DeviceClaimEntity.gsi1Pk(userId))
                .gsi1Sk(DeviceClaimEntity.gsi1Sk(claimId))
                .createdAt(Instant.now().minus(java.time.Duration.ofMinutes(11)))
                .lastModified(Instant.now())
                .build()

        def claim = DeviceClaimEntity.builder()
                .base(base)
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .deviceId(deviceId)
                .build()
        deviceClaimRepo.save(claim)

        when:
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimId, claimToken)

        then:
        def e = thrown(jct.pillorganizer.global.exception.ClaimTokenExpiredException)
        e.message == "Claim token expired"
    }
}
