package jct.pillorganizer.global.service;

import io.micronaut.core.annotation.Nullable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.core.service.SecureRandomService;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.core.uid.KsuidService;
import jct.pillorganizer.global.dto.DeviceClaimCertDto;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.exception.ClaimTokenExpiredException;
import jct.pillorganizer.global.exception.DeviceAccessException;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.repo.DeviceRepo;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.iot.IotClient;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimRequest;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimResponse;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

@Flogger
@Singleton
public class DeviceProvisionService {

    private final IotClient iotClient;
    private final DeviceClaimRepo deviceClaimRepo;
    private final DeviceRepo deviceRepo;
    private final DeviceService deviceService;
    private final TenantMessageService messageService;
    private final UserService userService;
    private final SecureRandomService secureRandomService;
    private final KsuidService ksuidService;
    private final TenantService tenantService;

    @Inject
    public DeviceProvisionService(IotClient iotClient, DeviceClaimRepo deviceClaimRepo, DeviceRepo deviceRepo,
                                  DeviceService deviceService, TenantMessageService messageService,
                                  UserService userService, SecureRandomService secureRandomService,
                                  KsuidService ksuidService, TenantService tenantService) {
        this.iotClient = iotClient;
        this.deviceClaimRepo = deviceClaimRepo;
        this.deviceService = deviceService;
        this.deviceRepo = deviceRepo;
        this.messageService = messageService;
        this.userService = userService;
        this.secureRandomService = secureRandomService;
        this.ksuidService = ksuidService;
        this.tenantService = tenantService;
    }

    private String generateClaimToken() {
        return secureRandomService.generateRandomToken();
    }

    public String generateThingName(String tenantId, String serialNumber, String deviceId) {
        return tenantId + "-" + serialNumber + "-" + deviceId;
    }

    private DeviceClaimEntity createClaimRecord(String serialNumber, String userId, String tenant, String deviceId) {
        String claimToken = generateClaimToken();
        String claimId = ksuidService.generateKsuid();
        String thingName = generateThingName(tenant, serialNumber, deviceId);

        DeviceClaimEntity entity = DeviceClaimEntity.builder()
                .base(DeviceClaimEntity.buildBase(serialNumber, claimId, claimToken, userId, deviceId))
                .serialNumber(serialNumber)
                .claimId(claimId)
                .claimToken(claimToken)
                .userId(userId)
                .tenantId(tenant)
                .deviceId(deviceId)
                .thingName(thingName)
                .build();

        deviceClaimRepo.save(entity);

        return entity;
    }


    public ProvisioningClaimDto generateProvisioningClaim(String serialNumber, String userId,
                                                          @Nullable String requestedDeviceId) {
        // Lookup which tenant this device belongs to
        String tenantId = deviceService.lookupTenant(serialNumber);
        TenantDetails tenantDetails = tenantService.getTenantDetails(tenantId)
                .orElseThrow(() -> new IllegalStateException("Device assigned to unregistered tenant: " + tenantId));

        String deviceId;
        if(requestedDeviceId == null) {
            deviceId = ksuidService.generateKsuid();
        } else {
            deviceId = requestedDeviceId;
        }

        // Check to see if the user can claim the request ID
        DeviceClaimEligibilityDto claimEligibility = messageService.getDeviceClaimEligibility(tenantId,
                        deviceId, serialNumber)
                .blockOptional(Duration.ofSeconds(5))
                .orElseThrow(() -> {
                    log.atWarning().log("Could not determine claim eligibility for user %s device %s", userId, deviceId);
                    return new DeviceAccessException("Could not determine claim eligibility");
                });

        // Ensure the user is eligible to claim the device
        if(!claimEligibility.isEligible()) {
            log.atWarning().log("Claim not eligible user %s device %s", userId, deviceId);
            throw new DeviceAccessException("Not eligible to claim device");
        }

        // If the user is requesting a specific device ID, it must exist
        if(requestedDeviceId != null && !claimEligibility.deviceExists()) {
            log.atWarning().log("User %s attempted to claim non-existent device %s", userId, deviceId);
            throw new DeviceAccessException("Not eligible to claim device");
        }

        // Create a claim token and store record
        DeviceClaimEntity claim = createClaimRecord(serialNumber, userId, tenantId, deviceId);

        return new ProvisioningClaimDto(claim.getClaimId(), tenantId, tenantDetails.getApiBase(), deviceId);
    }

    public DeviceClaimCertDto getClaimCertificate(String serialNumber, String claimId, String claimToken) {
        DeviceClaimEntity claim = deviceClaimRepo.findBySerialNumberAndClaimId(serialNumber, claimId)
                .orElseThrow(() -> {
                    log.atInfo().log("No claim found for serial number %s and claim id %s", serialNumber, claimId);
                    return new DeviceAccessException("No claim found");
                });

        // Ensure the presented claim token matches
        if (!claimToken.equals(claim.getClaimToken())) {
            log.atWarning().log("Invalid claim token presented for serial number %s (got %s received %s)", serialNumber,
                    claimToken, claim.getClaimToken());
            throw new DeviceAccessException("Invalid claim token");
        }

        // Ensure the token was issued within the last 10 minutes
        Instant tenMinutesAgo = Instant.now().minus(java.time.Duration.ofMinutes(10));
        if (claim.getBase().getCreatedAt().isBefore(tenMinutesAgo)) {
            log.atInfo().log("Claim token expired for serial number %s", serialNumber);
            throw new ClaimTokenExpiredException("Claim token expired");
        }

        // Generate claim credentials in IoT Core on demand
        CreateProvisioningClaimResponse response = iotClient.createProvisioningClaim(
                CreateProvisioningClaimRequest.builder()
                        .templateName("TenantDeviceProvisioningTemplate")
                        .build()
        );

        return new DeviceClaimCertDto(
                response.certificatePem(),
                response.keyPair().privateKey(),
                response.expiration()
        );
    }

    public DeviceEntity provisionDevice(String serialNumber, String claimId, String claimToken) {
        Optional<DeviceClaimEntity> claimOpt = deviceClaimRepo.findBySerialNumberAndClaimId(serialNumber, claimId);

        if (claimOpt.isEmpty()) {
            log.atInfo().log("No claim found for serial number %s and claim ID %s", serialNumber, claimId);
            throw new DeviceAccessException("Claim not found");
        }

        DeviceClaimEntity claim = claimOpt.get();

        if(!claim.getClaimToken().equals(claimToken)) {
            log.atWarning().log("Invalid claim token presented for serial number %s (got %s received %s)", serialNumber,
                    claimToken, claim.getClaimToken());
            throw new DeviceAccessException("Invalid claim token");
        }

        String deviceId = claim.getDeviceId();
        String tenantId = claim.getTenantId();
        String userId = claim.getUserId();
        String thingName = claim.getThingName();

        // Sanity check: tenant ID should match what we expect
        String assignedTenant = deviceService.lookupTenant(serialNumber);
        if(!assignedTenant.equals(tenantId)) {
            log.atWarning().log("Attempted to provision serial number %s to tenant %s, but it is assigned to %s",
                    serialNumber, tenantId, assignedTenant);
            throw new IllegalStateException("Invalid claim token");
        }

        // Check if device already exists to handle potential retries or concurrent provisioning
        Optional<DeviceEntity> existingDeviceOpt = deviceRepo.findBySerialNumber(serialNumber);

        DeviceEntity device;
        if (existingDeviceOpt.isPresent()) {
            device = existingDeviceOpt.get().toBuilder()
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .claimId(claimId)
                    .thingName(thingName)
                    .build();
        } else {
            device = DeviceEntity.builder()
                    .base(DeviceEntity.buildBase(serialNumber, tenantId, deviceId))
                    .serialNumber(serialNumber)
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .claimId(claimId)
                    .thingName(thingName)
                    .build();
        }

        // Persist updated/new device entity
        deviceRepo.save(device);

        // Lookup the current user
        UserEntity userEntity = userService.get(claim.getUserId())
                .orElseThrow(() -> new IllegalStateException("User not found: %s" + userId));

        // Let the tenant know they should have a user
        try {
            GrantUserMessage grantUserMessage = GrantUserMessage.builder()
                    .userId(userId)
                    .userName(userEntity.getUserName())
                    .email(userEntity.getEmail())
                    .tenantId(tenantId)
                    .build();
            messageService.grantUser(grantUserMessage);
        } catch (IOException ex) {
            log.atWarning().withCause(ex).log("Failed to notify tenant of user");
            throw new RuntimeException(ex);
        }

        // Let tenant know the device is provisioned
        try {
            DeviceProvisionMessage message = DeviceProvisionMessage.builder()
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .serialNo(serialNumber)
                    .userId(userId)
                    .claimId(claimId)
                    .thingName(thingName)
                    .build();
            messageService.provisionDevice(message);
        } catch (IOException ex) {
            log.atWarning().withCause(ex).log("Failed to notify tenant of provisioning");
            throw new RuntimeException(ex);
        }

        return device;
    }
}
