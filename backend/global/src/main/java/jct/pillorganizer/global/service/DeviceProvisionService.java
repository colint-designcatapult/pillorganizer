package jct.pillorganizer.global.service;

import com.github.ksuid.Ksuid;
import io.micronaut.multitenancy.exceptions.TenantNotFoundException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.core.service.SecureRandomService;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.core.uid.KsuidService;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.repo.DeviceRepo;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.enhanced.dynamodb.model.TransactPutItemEnhancedRequest;
import software.amazon.awssdk.services.iot.IotClient;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimRequest;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimResponse;

import java.io.IOException;
import java.security.SecureRandom;
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

    private String createClaimRecord(String serialNumber, String userId, String tenant) {
        String claimToken = generateClaimToken();

        deviceClaimRepo.save(
                DeviceClaimEntity.builder()
                        .base(DeviceClaimEntity.buildBase(serialNumber, claimToken, userId))
                        .serialNumber(serialNumber)
                        .claimToken(claimToken)
                        .userId(userId)
                        .tenantId(tenant)
                        .build()
        );

        return claimToken;
    }


    public ProvisioningClaimDto generateProvisioningClaim(String serialNumber, String userId) {
        // Create claim in IoT Core using provisioning template
        CreateProvisioningClaimResponse response = iotClient.createProvisioningClaim(
                CreateProvisioningClaimRequest.builder()
                        .templateName("TenantDeviceProvisioningTemplate")
                        .build()
        );

        // Lookup which tenant this device belongs to
        String tenantId = deviceService.lookupTenant(serialNumber);
        TenantDetails tenantDetails = tenantService.getTenantDetails(tenantId)
                .orElseThrow(() -> new TenantNotFoundException("Device assigned to unregistered tenant: " + tenantId));

        // Create a claim token
        String claimToken = createClaimRecord(serialNumber, userId, tenantId);

        return new ProvisioningClaimDto(response.certificatePem(), response.keyPair().privateKey(),
                response.expiration().toString(), claimToken, tenantId, tenantDetails.getApiBase());
    }

    public Optional<DeviceEntity> provisionDevice(String serialNumber, String claimToken) {
        Optional<DeviceClaimEntity> claimOpt = deviceClaimRepo.findBySerialNumberAndClaimToken(serialNumber, claimToken);

        if (claimOpt.isEmpty()) {
            log.atInfo().log("No claim found for serial number %s and claim token", serialNumber);
            return Optional.empty();
        }

        DeviceClaimEntity claim = claimOpt.get();
        String deviceId = ksuidService.generateKsuid();
        String tenantId = claim.getTenantId();
        String userId = claim.getUserId();

        // Check if device already exists to handle potential retries or concurrent provisioning
        Optional<DeviceEntity> existingDeviceOpt = deviceRepo.findBySerialNumber(serialNumber);

        DeviceEntity device;
        if (existingDeviceOpt.isPresent()) {
            device = existingDeviceOpt.get().toBuilder()
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .build();
        } else {
            device = DeviceEntity.builder()
                    .base(DeviceEntity.buildBase(serialNumber, tenantId, deviceId))
                    .serialNumber(serialNumber)
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .build();
        }

        // Lookup the current user
        UserEntity userEntity = userService.get(claim.getUserId())
                .orElseThrow(() -> new IllegalStateException("User not found: %s" + userId));

        DeviceClaimEntity updatedClaim = claim.toBuilder()
                .deviceId(deviceId)
                .build();

        // Perform transactional write to ensure both entities are updated together
        deviceRepo.getEnhancedClient().transactWriteItems(r -> r
                .addPutItem(deviceRepo.getTable(), TransactPutItemEnhancedRequest.builder(DeviceEntity.class)
                        .item(device)
                        .build())
                .addPutItem(deviceClaimRepo.getTable(), TransactPutItemEnhancedRequest.builder(DeviceClaimEntity.class)
                        .item(updatedClaim)
                        .build())
        );
        // Let the tenant know they should have a user record
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
            return Optional.empty();
        }

        // Let tenant know the device is provisioned
        try {
            DeviceProvisionMessage message = DeviceProvisionMessage.builder()
                    .deviceId(deviceId)
                    .tenantId(tenantId)
                    .serialNo(serialNumber)
                    .userId(userId)
                    .claimToken(claimToken)
                    .build();
            messageService.provisionDevice(message);
        } catch (IOException ex) {
            log.atWarning().withCause(ex).log("Failed to notify tenant of provisioning");
            return Optional.empty();
        }

        return Optional.of(device);
    }
}
