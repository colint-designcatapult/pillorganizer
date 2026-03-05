package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.global.dto.ClaimCertRequestDto;
import jct.pillorganizer.global.dto.DeviceClaimCertDto;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.dto.ProvisioningClaimRequestDto;
import jct.pillorganizer.global.service.DeviceProvisionService;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.http.annotation.Body;


@Controller("/device")
public class DeviceController {

    @Inject
    DeviceProvisionService provisionService;

    @Inject
    GlobalAuthService authService;

    @Post("/claim")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public ProvisioningClaimDto getProvisioningClaim(@Body ProvisioningClaimRequestDto requestDto) {
        return provisionService.generateProvisioningClaim(requestDto.serialNumber(), authService.getUserID(),
                requestDto.deviceId());
    }

    @Post("/claim_cert")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public DeviceClaimCertDto getClaimCertificate(@Body ClaimCertRequestDto request) {
        return provisionService.getClaimCertificate(request.serialNumber(), request.claimId(), request.claimToken());
    }

}
