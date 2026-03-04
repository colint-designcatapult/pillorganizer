package jct.pillorganizer.global.service

import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.service.SecureRandomService
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.model.BaseControlPlaneEntity
import jct.pillorganizer.global.model.DeviceClaimEntity
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.DeviceClaimRepo
import jct.pillorganizer.global.repo.DeviceRepo
import software.amazon.awssdk.services.iot.IotClient
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimResponse
import software.amazon.awssdk.services.iot.model.KeyPair
import spock.lang.Subject

import jakarta.inject.Inject
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
        def apiBase = "http://tenant1.api"

        def mockResponse = CreateProvisioningClaimResponse.builder()
                .certificatePem("cert-pem")
                .keyPair(KeyPair.builder().privateKey("private-key").build())
                .expiration(Instant.now().plusSeconds(3600))
                .build()

        and:
        iotClient.createProvisioningClaim(_) >> mockResponse
        deviceService.lookupTenant(serialNumber) >> tenantId
        tenantService.getTenantDetails(tenantId) >> Optional.of(new TenantDetails(tenantId, true, "Tenant 1", apiBase))

        when:
        def result = deviceProvisionService.generateProvisioningClaim(serialNumber, userId)

        then:
        result.tenantId() == tenantId
        result.tenantApiBase() == apiBase
        result.claimId() != null

        and:
        def savedClaim = deviceClaimRepo.findBySerialNumberAndClaimToken(serialNumber, result.claimId())
        savedClaim.isPresent()
        savedClaim.get().userId == userId
        savedClaim.get().tenantId == tenantId
    }

    def "should provision device successfully"() {
        given:
        def serialNumber = "SN-456"
        def claimToken = "token-456"
        def userId = "user-456"
        def tenantId = "tenant-456"
        def userName = "Test User"
        def email = "test@example.com"

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimToken, userId))
                .serialNumber(serialNumber)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .build()
        deviceClaimRepo.save(claim)

        and:
        userService.get(userId) >> Optional.of(UserEntity.builder()
                .userId(userId)
                .userName(userName)
                .email(email)
                .build())

        when:
        def result = deviceProvisionService.provisionDevice(serialNumber, claimToken)

        then:
        result.isPresent()
        result.get().serialNumber == serialNumber
        result.get().tenantId == tenantId
        def deviceId = result.get().deviceId

        and:
        def savedDevice = deviceRepo.findBySerialNumber(serialNumber)
        savedDevice.isPresent()
        savedDevice.get().deviceId == deviceId

        and:
        def updatedClaim = deviceClaimRepo.findBySerialNumberAndClaimToken(serialNumber, claimToken)
        updatedClaim.isPresent()
        updatedClaim.get().deviceId == deviceId

        and:
        1 * messageService.grantUser({ it.userId == userId && it.userName == userName })
        1 * messageService.provisionDevice({ it.deviceId != null && it.serialNo == serialNumber })
    }

    def "should return empty when claim not found"() {
        given:
        def serialNumber = "SN-UNKNOWN"
        def claimToken = "invalid-token"

        when:
        def result = deviceProvisionService.provisionDevice(serialNumber, claimToken)

        then:
        !result.isPresent()
        0 * messageService._
    }

    def "should return certificate when claim is valid"() {
        given:
        def serialNumber = "SN-CERT-1"
        def claimToken = "token-cert-1"
        def userId = "user-cert-1"
        def tenantId = "tenant-cert-1"

        def claim = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimToken, userId))
                .serialNumber(serialNumber)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
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
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimToken)

        then:
        result.isPresent()
        result.get().certificatePem() == "cert-pem"
        result.get().privateKey() == "private-key"
    }

    def "should return empty when claim not found for certificate"() {
        given:
        def serialNumber = "SN-UNKNOWN"
        def claimToken = "invalid-token"

        when:
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimToken)

        then:
        !result.isPresent()
    }

    def "should return empty when claim is expired"() {
        given:
        def serialNumber = "SN-EXPIRED"
        def claimToken = "token-expired"
        def userId = "user-expired"
        def tenantId = "tenant-expired"

        def base = BaseControlPlaneEntity.builder()
                .pk(DeviceClaimEntity.pk(serialNumber))
                .sk(DeviceClaimEntity.sk(claimToken))
                .entityType(DeviceControlPlaneEntityType.DEVICE_CLAIM)
                .gsi1Pk(DeviceClaimEntity.gsi1Pk(userId))
                .gsi1Sk(DeviceClaimEntity.gsi1Sk(claimToken))
                .createdAt(Instant.now().minus(java.time.Duration.ofMinutes(11)))
                .lastModified(Instant.now())
                .build()

        def claim = DeviceClaimEntity.builder()
                .base(base)
                .serialNumber(serialNumber)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenantId)
                .build()
        deviceClaimRepo.save(claim)

        when:
        def result = deviceProvisionService.getClaimCertificate(serialNumber, claimToken)

        then:
        !result.isPresent()
    }
}
