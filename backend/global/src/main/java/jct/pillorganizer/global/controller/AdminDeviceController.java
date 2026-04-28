package jct.pillorganizer.global.controller;

import io.micronaut.core.annotation.Blocking;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.http.HttpStatus;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.global.dto.AdminDeviceClaimSummaryDto;
import jct.pillorganizer.global.dto.AdminDeviceDetailDto;
import jct.pillorganizer.global.dto.AdminDevicePageDto;
import jct.pillorganizer.global.dto.AdminDeviceSummaryDto;
import jct.pillorganizer.global.dto.AdminDeviceTenantMappingDto;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.repo.DeviceTenantMappingRepo;
import jct.pillorganizer.global.repo.PageResult;

import java.util.List;
import java.util.stream.Collectors;

@Controller("/admin/devices")
@Secured(AppSecurityRule.IS_GLOBAL_ADMIN)
@Blocking
public class AdminDeviceController {

    @Inject
    DeviceRepo deviceRepo;

    @Inject
    DeviceClaimRepo deviceClaimRepo;

    @Inject
    DeviceTenantMappingRepo deviceTenantMappingRepo;

    @Get
    public AdminDevicePageDto listDevices(
            @Nullable @QueryValue String cursor,
            @Nullable @QueryValue String snFilter,
            @QueryValue(defaultValue = "20") int size) {
        PageResult<DeviceEntity> result = deviceRepo.findAllPaginated(size, cursor, snFilter);
        List<AdminDeviceSummaryDto> items = result.items().stream()
                .map(AdminDeviceSummaryDto::from)
                .collect(Collectors.toList());
        return new AdminDevicePageDto(items, result.nextCursor());
    }

    @Get("/{serialNumber}")
    public AdminDeviceDetailDto getDevice(@PathVariable String serialNumber) {
        DeviceEntity device = deviceRepo.findBySerialNumber(serialNumber)
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND, "Device not found: " + serialNumber));

        List<AdminDeviceClaimSummaryDto> claims = deviceClaimRepo.findAllBySerialNumber(serialNumber)
                .stream()
                .map(AdminDeviceClaimSummaryDto::from)
                .collect(Collectors.toList());

        AdminDeviceTenantMappingDto tenantMapping = deviceTenantMappingRepo.findBySerialNumber(serialNumber)
                .map(AdminDeviceTenantMappingDto::from)
                .orElse(null);

        return AdminDeviceDetailDto.from(device, claims, tenantMapping);
    }
}

