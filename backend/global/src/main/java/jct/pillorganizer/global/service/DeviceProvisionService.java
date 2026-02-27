package jct.pillorganizer.global.service;

import com.github.ksuid.Ksuid;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.repo.DeviceRepo;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.iot.IotClient;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimRequest;
import software.amazon.awssdk.services.iot.model.CreateProvisioningClaimResponse;

import java.util.Optional;

@Flogger
@Singleton
public class DeviceProvisionService {

    private final IotClient iotClient;
    private final DeviceClaimRepo deviceClaimRepo;
    private final DeviceRepo deviceRepo;
    private final DeviceService deviceService;

    @Inject
    public DeviceProvisionService(IotClient iotClient, DeviceClaimRepo deviceClaimRepo, DeviceRepo deviceRepo, DeviceService deviceService) {
        this.iotClient = iotClient;
        this.deviceClaimRepo = deviceClaimRepo;
        this.deviceService = deviceService;
        this.deviceRepo = deviceRepo;
    }

    private String createClaimRecord(String serialNumber, String userId, String tenant) {
        String claimToken = Ksuid.newKsuid().toString();

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

        // Create a claim token
        String claimToken = createClaimRecord(serialNumber, userId, tenantId);

        return new ProvisioningClaimDto(response.certificatePem(), response.keyPair().privateKey(),
                response.expiration().toString(), claimToken, tenantId);
    }

    public Optional<DeviceEntity> provisionDevice(String serialNumber, String claimToken) {
        Optional<DeviceClaimEntity> claimOpt = deviceClaimRepo.findBySerialNumberAndClaimToken(serialNumber, claimToken);

        if (claimOpt.isEmpty()) {
            log.atInfo().log("No claim found for serial number %s and claim token", serialNumber);
            return Optional.empty();
        }

        DeviceClaimEntity claim = claimOpt.get();
        String deviceId = Ksuid.newKsuid().toString();
        String tenantId = claim.getTenantId();

        DeviceEntity device = DeviceEntity.builder()
                .base(DeviceEntity.buildBase(serialNumber, tenantId, deviceId))
                .serialNumber(serialNumber)
                .deviceId(deviceId)
                .tenantId(tenantId)
                .build();

        DeviceClaimEntity updatedClaim = claim.toBuilder()
                .deviceId(deviceId)
                .build();

        // Perform transactional write to ensure both entities are updated together
        deviceRepo.getEnhancedClient().transactWriteItems(r -> r
                .addPutItem(deviceRepo.getTable(), device)
                .addPutItem(deviceClaimRepo.getTable(), updatedClaim)
        );

        return Optional.of(device);
    }
}
