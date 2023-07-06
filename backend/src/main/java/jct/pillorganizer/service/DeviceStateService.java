package jct.pillorganizer.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.device.DeviceStateWrapper;
import jct.pillorganizer.dto.DosePeriodDTO;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceState;
import jct.pillorganizer.model.medication.MedicationDispenseTime;
import jct.pillorganizer.repo.DeviceEventRepository;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceScheduleRepository;
import jct.pillorganizer.repo.DeviceStateRepository;

import javax.transaction.Transactional;
import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Business logic for dealing with device state.
 */
@Singleton
public class DeviceStateService {

    @Inject
    DeviceStateRepository deviceStateRepository;

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceScheduleRepository deviceScheduleRepository;

    @Inject
    DeviceEventRepository deviceEventRepository;

    @Inject
    FirmwareService firmwareService;


    /**
     * Creates a `DeviceStateWrapper` for a particular device.
     * @param device the device to create a wrapper around
     * @return a DeviceStateWrapper that operates on a particular device
     */
    public DeviceStateWrapper wrapperOf(Device device) {
        return new DeviceStateWrapper(deviceRepository, deviceScheduleRepository,
                deviceStateRepository, deviceEventRepository, firmwareService, device);
    }


    /**
     * Packs the status field of every bin state of a device into a single long. This is an optimization trip so that
     * we don't need to store or serialize the status of every bin into an array of integers. Instead we only need one
     * integer.
     * @param device device to calculate the state flag on
     * @return a long representing the packed status of every bin state
     */
    public long calculateStateFlags(Device device) {
        long flags = 0;
        List<DeviceState> bins = deviceStateRepository.findByDevice(device);

        for (DeviceState bin : bins) {
            long statusInt = bin.getBinStatus().getIntValue();
            long binNum = bin.getId().getBinID();
            flags |= (statusInt << (4 * binNum));
        }
        return flags;
    }

    /**
     * Builds a compact representation of a device's state around a particular date. Only information relevant to that
     * date is included in the resultant list.
     * @param device device to build the dose period for
     * @param date the date that all dose periods should be on
     * @return a list of DosePeriodDTO objects, representing a time on the specified date that medication is taken
     */
    @Transactional
    public List<DosePeriodDTO> buildDosePeriod(Device device, LocalDate date) {
        ZonedDateTime startOfDay = date.atStartOfDay(device.getTimeZone());
        ZonedDateTime endOfDay = startOfDay.plusDays(1);

        List<DeviceState> states = deviceStateRepository.findByDeviceAndTimeBetween(device, startOfDay.toEpochSecond(),
                endOfDay.toEpochSecond());

        List<DosePeriodDTO> dtos = new ArrayList<>(states.size());
        for(DeviceState state : states) {
            List<Long> medicationIDs = state.getDispenseTime().getMedications()
                    .stream()
                    .map(MedicationDispenseTime::getMedicationID)
                    .toList();

            dtos.add(new DosePeriodDTO(
                    (short) state.getId().getBinID(),
                    state.getScheduledTime(),
                    (short) state.getBinStatus().getIntValue(),
                    medicationIDs)
            );
        }
        return dtos;
    }


}
