package jct.pillorganizer.tenant.api.dashboard;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.tenant.dto.*;
import jct.pillorganizer.tenant.projection.DeviceUserAdherenceSummaryView;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import jct.pillorganizer.tenant.service.AdherenceService;
import lombok.extern.flogger.Flogger;

import java.time.LocalDate;
import java.util.List;

@Controller("/tenant-admin")
@Flogger
@Secured(AppSecurityRule.IS_TENANT_ADMIN)
public class TenantDashboardController {

    @Inject DeviceEventRepository deviceEventRepository;
    @Inject AdherenceService adherenceService;

    @Get("/devices")
    public TenantDevicePageDto listDevices(
            @QueryValue(defaultValue = "20") int size,
            @Nullable @QueryValue String cursor,
            @Nullable @QueryValue String snFilter) {

        LocalDate now = LocalDate.now();
        int year = now.getYear();
        int month = now.getMonthValue();

        // Cursor encodes "serialNo|||userId"
        String cursorSn = null;
        String cursorUid = null;
        if (cursor != null) {
            String[] parts = cursor.split("\\|\\|\\|", 2);
            if (parts.length == 2) {
                cursorSn = parts[0];
                cursorUid = parts[1];
            }
        }

        List<DeviceUserAdherenceSummaryView> results = deviceEventRepository.getDeviceUserAdherenceSummaries(
                year, month, snFilter, cursorSn, cursorUid, size + 1);

        String nextCursor = null;
        List<DeviceUserAdherenceSummaryView> page = results;
        if (results.size() > size) {
            page = results.subList(0, size);
            DeviceUserAdherenceSummaryView last = page.get(page.size() - 1);
            nextCursor = last.serialNumber() + "|||" + last.userId();
        }

        List<TenantDeviceSummaryDto> items = page.stream()
                .map(v -> new TenantDeviceSummaryDto(
                        v.deviceId(),
                        v.serialNumber(),
                        v.userId(),
                        v.subjectId(),
                        v.dosesTaken(),
                        v.dosesScheduled()))
                .toList();

        return new TenantDevicePageDto(items, nextCursor);
    }

    @Get("/devices/{deviceId}/adherence")
    public DeviceAdherenceResponseDto getDeviceAdherence(
            @PathVariable String deviceId,
            @QueryValue(defaultValue = "0") int year,
            @QueryValue(defaultValue = "0") int month) {
        LocalDate now = LocalDate.now();
        int y = year > 0 ? year : now.getYear();
        int m = month > 0 ? month : now.getMonthValue();
        log.atInfo().log("Tenant admin fetching adherence for device %s %d-%02d", deviceId, y, m);
        return adherenceService.getDeviceAdherence(deviceId, y, m);
    }
}
