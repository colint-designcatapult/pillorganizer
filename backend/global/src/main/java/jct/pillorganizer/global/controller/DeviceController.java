package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.global.dto.ClaimCertRequestDto;
import jct.pillorganizer.global.dto.DeviceClaimCertDto;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.service.DeviceProvisionService;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.http.annotation.Body;

import java.util.Optional;

@Controller("/device")
public class DeviceController {

    @Inject
    DeviceProvisionService provisionService;

    @Inject
    GlobalAuthService authService;

    @Post("/claim/{serialNumber}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public ProvisioningClaimDto getProvisioningClaim(@PathVariable String serialNumber) {
        return provisionService.generateProvisioningClaim(serialNumber, authService.getUserID());
    }

    @Post("/claim_cert/{serialNumber}")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public DeviceClaimCertDto getClaimCertificate(@PathVariable String serialNumber, @Body ClaimCertRequestDto request) {
        return provisionService.getClaimCertificate(serialNumber, request.claimId())
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND, "Claim not found or expired"));
    }

}
