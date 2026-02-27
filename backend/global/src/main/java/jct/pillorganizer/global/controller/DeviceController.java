package jct.pillorganizer.global.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;
import jct.pillorganizer.global.dto.ProvisioningClaimDto;
import jct.pillorganizer.global.service.DeviceProvisionService;

@Controller("/device")
public class DeviceController {

    @Inject
    DeviceProvisionService provisionService;

    @Post("/claim/{serialNumber}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public ProvisioningClaimDto getProvisioningClaim(@PathVariable String serialNumber) {
        return provisionService.generateProvisioningClaim(serialNumber, "test");
    }

}
