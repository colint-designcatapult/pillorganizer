package jct.pillorganizer.global.controller;

import io.micronaut.http.HttpHeaders;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.global.dto.DeviceNotificationRequestDto;
import jct.pillorganizer.global.dto.RegisterFcmTokenDto;
import jct.pillorganizer.global.dto.UserAndDeviceAccessDto;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.service.UserDeviceAccessService;
import jct.pillorganizer.global.service.UserService;
import reactor.core.publisher.Mono;

@Controller("/user")
@Secured(AppSecurityRule.IS_USER)
public class UserDeviceAccessController {

    @Inject
    UserDeviceAccessService userDeviceAccessService;

    @Inject
    UserService userService;

    @Inject
    GlobalAuthService authService;

    @Get("/devices")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<UserAndDeviceAccessDto> listDevices() {
        return userDeviceAccessService.getUserDeviceAccess()
                .collectList()
                .map(UserAndDeviceAccessDto::new);
    }

    /**
     * Registers or refreshes the authenticated user's FCM token as an SNS
     * platform-application endpoint. Should be called on first launch and
     * whenever the FCM token is refreshed.
     *
     * @param dto contains the current {@code fcmToken}
     */
    @Post("/fcm_token")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<Void> registerFcmToken(@Body @Valid RegisterFcmTokenDto dto) {
        return Mono.fromCallable(() -> {
            String userId = authService.getUserID();
            UserEntity user = userService.get(userId)
                    .orElseThrow(() -> new IllegalStateException("User not found: " + userId));
            userService.registerFcmToken(user, dto.fcmToken());
            return null;
        });
    }

    /**
     * Subscribes or unsubscribes the authenticated user from push notifications
     * for a device. Forwards the request to the appropriate tenant module,
     * passing the user's JWT so the tenant can authenticate and identify the caller.
     *
     * @param dto           contains {@code deviceId}, {@code tenantId}, and {@code subscribe} flag
     * @return updated {@link DeviceAccessDto} with the refreshed {@code notifications} flag
     */
    @Post("/device/notifications")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<DeviceAccessDto> updateDeviceNotifications(@Body @Valid DeviceNotificationRequestDto dto) {
        String userId = authService.getUserID();
        return Mono.fromCallable(() -> userService.get(userId)
                        .orElseThrow(() -> new IllegalStateException("User not found: " + userId)))
                .flatMap(user -> userDeviceAccessService.updateDeviceNotifications(dto.tenantId(),
                        dto.deviceId(), user, dto.subscribe()));
    }
}

