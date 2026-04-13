package jct.pillorganizer.tenant.api.internal;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.dto.DeviceClaimEligibilityDto;
import jct.pillorganizer.core.dto.DeviceEligibilityCheckDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.DeviceNotificationSubscribeDto;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.service.DeviceIotService;
import jct.pillorganizer.tenant.service.DeviceNotificationService;
import jct.pillorganizer.tenant.service.DeviceProvisionService;
import jct.pillorganizer.tenant.service.DeviceService;

import java.util.List;
import java.util.Optional;

@Controller("/internal/user")
public class InternalUserController {

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceIotService deviceIotService;

    @Inject
    DeviceNotificationService deviceNotificationService;

    @Inject
    AuthService authService;


    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public List<DeviceAccessDto> devices(User user) {
        return deviceService.getUserDevices(user);
    }

    @Get("/device_access_policy")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Optional<String> getDevicePolicyDocument(User user, @QueryValue String deviceId) {
        Optional<DeviceUser> access = deviceService.getUserAccess(user, deviceId);
        return access.map(du -> deviceIotService.generateDeviceUserAccessPolicyDocument(du));
    }

    @Post("/device_claim_eligibility")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceClaimEligibilityDto getDeviceClaimEligibility(User user, @Body DeviceEligibilityCheckDto checkDto) {
        DeviceService.ClaimEligibility eligibility = deviceService.getDeviceClaimEligibility(user,
                checkDto.serialNo(), checkDto.deviceId());
        return new DeviceClaimEligibilityDto(eligibility.isEligible(), eligibility.device().isPresent());
    }

    /**
     * Subscribes or unsubscribes the authenticated user from push notifications for a device.
     * The caller must have (non-primary) access to the device.
     *
     * @param deviceId the logical device ID
     * @param dto      {@code subscribe=true} to opt in, {@code false} to opt out;
     *                 {@code endpointArn} is the user's SNS platform-endpoint ARN
     * @return updated {@link DeviceAccessDto} with the refreshed {@code notifications} flag
     */
    @Post("/device/{deviceId}/notifications")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceAccessDto updateNotifications(@PathVariable String deviceId,
                                               @Body @Valid DeviceNotificationSubscribeDto dto,
                                               User user) {
        LogicalDevice device = authService.accessDevice(deviceId, false);
        if (dto.subscribe()) {
            return deviceNotificationService.subscribe(user, device, dto.endpointArn());
        } else {
            return deviceNotificationService.unsubscribe(user, device);
        }
    }
}
