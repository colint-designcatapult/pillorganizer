package jct.pillorganizer.tenant.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.*;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;
import jct.pillorganizer.tenant.model.schedule.DosePeriod;
import jct.pillorganizer.tenant.model.schedule.SimpleSchedule;
import jct.pillorganizer.tenant.projection.DoseHistoryView;
import jct.pillorganizer.tenant.repo.DeviceEventRepository;
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository;
import lombok.extern.flogger.Flogger;

import java.time.*;
import java.util.ArrayList;
import java.util.List;

@Flogger
@Singleton
public class AdherenceService {

    @Inject DeviceEventRepository deviceEventRepository;
    @Inject DeviceScheduleRepository deviceScheduleRepository;
    @Inject ObjectMapper objectMapper;

    public List<DoseHistoryDto> getAdherenceHistory(String deviceId, int year, int month) {
        var appliedSchedules = deviceScheduleRepository.findByDeviceIdAndStatus(deviceId, ScheduleStatus.APPLIED);
        if (appliedSchedules.isEmpty()) {
            log.atWarning().log("No APPLIED schedules found for device: %s", deviceId);
            return List.of();
        }

        String deviceTimeZone = appliedSchedules.get(0).getTimezoneIana();
        if (deviceTimeZone == null) {
            log.atSevere().log("APPLIED schedule has null timezone for device: %s", deviceId);
            return List.of();
        }

        List<DoseHistoryView> doseHistory = deviceEventRepository.getResolvedMonthAdherenceHistory(deviceId, year, month, deviceTimeZone);
        log.atInfo().log("Query returned %d results for %s %d-%02d", doseHistory.size(), deviceId, year, month);
        return doseHistory.stream()
                .map(view -> new DoseHistoryDto(view.logicalDeviceId(), view.epochWeek(), view.binId(),
                        view.scheduledTime(), view.finalStatus(), view.resolvedTime(), view.deviceTimeZone()))
                .toList();
    }

    public DeviceAdherenceResponseDto getDeviceAdherence(String deviceId, int year, int month) {
        var appliedSchedules = deviceScheduleRepository.findByDeviceIdAndStatus(deviceId, ScheduleStatus.APPLIED);

        String tz = "UTC";
        Instant weekStart = Instant.now();
        List<ScheduleBinDto> scheduleBins = new ArrayList<>();

        if (!appliedSchedules.isEmpty()) {
            DeviceSchedule schedule = appliedSchedules.get(0);
            tz = schedule.getTimezoneIana() != null ? schedule.getTimezoneIana() : "UTC";

            ZoneId zone = ZoneId.of(tz);
            LocalDate monday = LocalDate.now(zone).with(DayOfWeek.MONDAY);
            weekStart = monday.atStartOfDay(zone).toInstant();

            try {
                SimpleSchedule simpleSchedule = objectMapper.readValue(schedule.getScheduleJson(), SimpleSchedule.class);
                if (simpleSchedule.getBins() != null) {
                    List<DosePeriod> bins = simpleSchedule.getBins();
                    for (int i = 0; i < bins.size(); i++) {
                        DosePeriod dp = bins.get(i);
                        scheduleBins.add(new ScheduleBinDto(i, dp.getDayOfWeek(), dp.getTime()));
                    }
                }
            } catch (Exception e) {
                log.atSevere().withCause(e).log("Failed to parse schedule JSON for device %s", deviceId);
            }
        } else {
            log.atWarning().log("No APPLIED schedules found for device: %s", deviceId);
        }

        List<DoseHistoryDto> history = getAdherenceHistory(deviceId, year, month);
        return new DeviceAdherenceResponseDto(tz, weekStart, scheduleBins, history);
    }
}
