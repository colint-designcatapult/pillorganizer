package jct.pillorganizer.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.dto.SimpleScheduleDTO;
import jct.pillorganizer.model.device.DayOfWeek;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceBinId;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;
import jct.pillorganizer.model.device.schedule.DeviceBaseScheduleStrategy;
import jct.pillorganizer.model.device.schedule.DeviceSimpleDispenseTime;
import jct.pillorganizer.model.device.schedule.DeviceSimpleScheduleStrategy;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceScheduleRepository;
import jct.pillorganizer.repo.DeviceScheduleStrategyRepository;
import jct.pillorganizer.repo.DeviceSimpleDispenseTimeRepository;

import javax.transaction.Transactional;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Business logic for dealing with device scheduling.
 */
@Singleton
public class DeviceScheduleService {

    @Inject
    DeviceScheduleRepository deviceScheduleRepository;

    @Inject
    DeviceScheduleStrategyRepository strategyRepository;

    @Inject
    DeviceSimpleDispenseTimeRepository dispenseTimeRepository;

    @Inject
    BinService binService;

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceStateService deviceStateService;


    /**
     * Fetches a device's simplified schedule DTO. If the device has no schedule registered, an empty schedule is
     * returned.
     * @param deviceUser the device to fetch the schedule for
     * @return specified device's schedule in simplified DTO format
     */
    public SimpleScheduleDTO buildSimpleSchedule(DeviceUser deviceUser) {
        return strategyRepository.findByDeviceUser(deviceUser)
                .map(this::buildSimpleSchedule)
                .orElseGet(SimpleScheduleDTO::empty);
    }


    private SimpleScheduleDTO buildSimpleSchedule(DeviceBaseScheduleStrategy strategy) {
        if(strategy instanceof DeviceSimpleScheduleStrategy) {
            return (SimpleScheduleDTO) strategy.buildDTO();
        } else {
            throw new IllegalArgumentException("Not using simple strategy");
        }
    }

    /**
     * Updates a device's schedule based on the specified simplified schedule DTO. This function hides the complexity of
     * the underlying schedule strategy class structure. If a device doesn't have a schedule strategy yet, a new one
     * is created and persisted automatically.
     * @param device device to apply the schedule on
     * @param dto a schedule DTO
     * @return a new schedule DTO that includes the new changes
     */
    public SimpleScheduleDTO updateSchedule(Device device, DeviceUser deviceUser, SimpleScheduleDTO dto) {
        DeviceBaseScheduleStrategy strat = strategyRepository.findByDeviceUser(deviceUser)
                .orElseGet(() -> buildDefaultSchedule(deviceUser));
        return updateSchedule(device, deviceUser, strat, dto);
    }

    /**
     * Converts a day-epoch format time into a LocalTime.
     * @param secondsFrom00 day-epoch format to convert
     * @return converted LocalTime
     */
    public LocalTime fromSecondsFrom00(long secondsFrom00) {
        return LocalTime.MIDNIGHT.plusSeconds(secondsFrom00);
    }

    private DeviceBaseScheduleStrategy buildDefaultSchedule(DeviceUser deviceUser) {
        DeviceSimpleScheduleStrategy s = new DeviceSimpleScheduleStrategy();
        s.setTimes(Set.of());
        s.setDeviceUser(deviceUser);

        return strategyRepository.save(s);
    }

    private SimpleScheduleDTO updateSchedule(Device device, DeviceUser deviceUser, DeviceBaseScheduleStrategy strategy, SimpleScheduleDTO dto) {
        if(strategy instanceof DeviceSimpleScheduleStrategy) {
            return updateSimpleSchedule(device, deviceUser, (DeviceSimpleScheduleStrategy) strategy, dto);
        } else {
            throw new IllegalArgumentException("Only simple strategy supported at this time");
        }
    }




    @Transactional
    void updateDeviceSchedule(Device d, DeviceUser deviceUser, DeviceSimpleScheduleStrategy strategy, DayOfWeek dayOfWeek) {

        // this is an ugly hack that needs to be removed
        // just get rid of DeviceSchedule already

        DeviceSimpleDispenseTime am = strategy.amTime();
        DeviceSimpleDispenseTime pm = strategy.pmTime();

        DeviceBinId amBin = new DeviceBinId(deviceUser.getId(), binService.getBinID(d.getDeviceClass(), dayOfWeek, 'A'));
        DeviceBinId pmBin = new DeviceBinId(deviceUser.getId(), binService.getBinID(d.getDeviceClass(), dayOfWeek, 'P'));

        if(am == null) {
            deviceScheduleRepository.update(
                    amBin,
                    DayOfWeek.DISABLED,
                    0,
                    null
            );
        } else {
            deviceScheduleRepository.update(
                    amBin,
                    dayOfWeek,
                    Math.toIntExact(am.toSecondsFrom00()),
                    am
            );
        }

        if(pm == null) {
            deviceScheduleRepository.update(
                    pmBin,
                    DayOfWeek.DISABLED,
                    0,
                    null
            );
        } else {
            deviceScheduleRepository.update(
                    pmBin,
                    dayOfWeek,
                    Math.toIntExact(pm.toSecondsFrom00()),
                    pm
            );
        }
    }

    @Transactional
    void updateDeviceSchedule(Device d, DeviceUser deviceUser, DeviceBaseScheduleStrategy strategy, DayOfWeek dayOfWeek) {
        if(strategy instanceof DeviceSimpleScheduleStrategy) {
            updateDeviceSchedule(d, deviceUser, (DeviceSimpleScheduleStrategy) strategy, dayOfWeek);
        } else {
            throw new RuntimeException("Unknown strategy");
        }
    }

    @Transactional(Transactional.TxType.REQUIRES_NEW)
    void updateDeviceSchedule(Device d, DeviceUser deviceUser) {
        DeviceBaseScheduleStrategy strategy = strategyRepository.findByDeviceUser(deviceUser)
                .orElseThrow();

        for(DayOfWeek dayOfWeek : DayOfWeek.values()) {
            if(dayOfWeek == DayOfWeek.DISABLED)
                continue;

            updateDeviceSchedule(d, deviceUser, strategy, dayOfWeek);
        }

        deviceStateService.wrapperOf(d, deviceUser).rebuildStateSchedule();

    }

    @Transactional
    SimpleScheduleDTO updateDispenseTime(Device d, DeviceSimpleScheduleStrategy strategy, SimpleScheduleDTO dto) {
        Map<Character, DeviceSimpleDispenseTime> map = new HashMap<>(2);

        for(DeviceBaseDispenseTime bdt : strategy.getTimes()) {
            DeviceSimpleDispenseTime dt = (DeviceSimpleDispenseTime) bdt;
            map.put(dt.getPeriod(), dt);
        }

        Long amID = null, am00 = null, pmID = null, pm00 = null;

        if(dto.amSecondsFrom00() != null) {
            if(map.containsKey('A')) {
                // Update AM
                amID = map.get('A').getId();
                dispenseTimeRepository.update(amID, fromSecondsFrom00(dto.amSecondsFrom00()));

            } else {
                // Insert AM
                DeviceSimpleDispenseTime dt = new DeviceSimpleDispenseTime();
                dt.setSchedule(strategy);
                dt.setPeriod('A');
                dt.setTime(fromSecondsFrom00(dto.amSecondsFrom00()));
                amID = dispenseTimeRepository.save(dt).getId();
            }
            am00 = dto.amSecondsFrom00();
        }
        if(dto.pmSecondsFrom00() != null) {
            if(map.containsKey('P')) {
                // Update PM
                pmID = map.get('P').getId();
                dispenseTimeRepository.update(pmID, fromSecondsFrom00(dto.pmSecondsFrom00()));
            } else {
                // Insert PM
                DeviceSimpleDispenseTime dt = new DeviceSimpleDispenseTime();
                dt.setSchedule(strategy);
                dt.setPeriod('P');
                dt.setTime(fromSecondsFrom00(dto.pmSecondsFrom00()));
                pmID = dispenseTimeRepository.save(dt).getId();
            }
            pm00 = dto.pmSecondsFrom00();
        }
        return new SimpleScheduleDTO(amID, am00, pmID, pm00);
    }

    SimpleScheduleDTO updateSimpleSchedule(Device d, DeviceUser deviceUser, DeviceSimpleScheduleStrategy strategy, SimpleScheduleDTO dto) {
        SimpleScheduleDTO simpleScheduleDTO = updateDispenseTime( d,  strategy,  dto);
        updateDeviceSchedule(d, deviceUser);
        return simpleScheduleDTO;
    }
}
