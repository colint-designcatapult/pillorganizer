package jct.pillorganizer.global.controller;

import io.micronaut.core.annotation.Blocking;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.global.dto.AdminDeviceTenantMappingDto;
import jct.pillorganizer.global.dto.AdminTenantDetailDto;
import jct.pillorganizer.global.dto.AdminTenantDevicePageDto;
import jct.pillorganizer.global.dto.AdminTenantDeviceRowDto;
import jct.pillorganizer.global.dto.AdminTenantSummaryDto;
import jct.pillorganizer.global.dto.AssignDeviceToTenantRequestDto;
import jct.pillorganizer.global.model.DeviceTenantMappingEntity;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.repo.DeviceTenantMappingRepo;
import jct.pillorganizer.global.repo.PageResult;

import java.util.Collection;
import java.util.List;

@Controller("/admin/tenants")
@Secured(AppSecurityRule.IS_GLOBAL_ADMIN)
@Blocking
public class AdminTenantController {

    @Inject
    Collection<TenantDetails> tenantDetails;

    @Inject
    DeviceRepo deviceRepo;

    @Inject
    DeviceTenantMappingRepo deviceTenantMappingRepo;

    @Get
    public List<AdminTenantSummaryDto> listTenants() {
        return tenantDetails.stream()
                .map(AdminTenantSummaryDto::from)
                .toList();
    }

    @Get("/{tenantId}")
    public AdminTenantDetailDto getTenant(@PathVariable String tenantId) {
        TenantDetails tenant = resolveTenant(tenantId);
        return AdminTenantDetailDto.from(tenant);
    }

    @Get("/{tenantId}/devices")
    public AdminTenantDevicePageDto getTenantDevices(
            @PathVariable String tenantId,
            @Nullable @QueryValue String cursor,
            @QueryValue(defaultValue = "20") int size,
            @Nullable @QueryValue String snFilter) {
        resolveTenant(tenantId);

        PageResult<DeviceTenantMappingEntity> result =
                deviceTenantMappingRepo.findAllByTenantIdPaginated(tenantId, size, cursor, snFilter);

        List<AdminTenantDeviceRowDto> rows = result.items().stream()
                .map(mapping -> AdminTenantDeviceRowDto.from(
                        mapping,
                        deviceRepo.findBySerialNumber(mapping.getSerialNumber()).orElse(null)))
                .toList();

        return new AdminTenantDevicePageDto(rows, result.nextCursor());
    }

    @Post("/{tenantId}/device-mappings")
    public AdminDeviceTenantMappingDto assignDevice(
            @PathVariable String tenantId,
            @Body AssignDeviceToTenantRequestDto request) {
        resolveTenant(tenantId);

        DeviceTenantMappingEntity entity = DeviceTenantMappingEntity.builder()
                .base(DeviceTenantMappingEntity.buildBase(request.serialNumber(), tenantId))
                .serialNumber(request.serialNumber())
                .tenantId(tenantId)
                .build();

        deviceTenantMappingRepo.save(entity);
        return AdminDeviceTenantMappingDto.from(entity);
    }

    private TenantDetails resolveTenant(String tenantId) {
        return tenantDetails.stream()
                .filter(t -> t.getId().equals(tenantId))
                .findFirst()
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND, "Tenant not found: " + tenantId));
    }
}
