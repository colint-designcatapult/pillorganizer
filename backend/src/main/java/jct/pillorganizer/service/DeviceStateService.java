package jct.pillorganizer.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import javax.transaction.Transactional;

import org.zalando.problem.Problem;

import io.micronaut.http.HttpStatus;
import io.micronaut.problem.HttpStatusType;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.auth.DeviceAuthService;
import jct.pillorganizer.device.DeviceStateWrapper;
import jct.pillorganizer.dto.DosePeriodDTO;
import jct.pillorganizer.model.EventType;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceEvent;
import jct.pillorganizer.model.device.DeviceProvision;
import jct.pillorganizer.model.device.DeviceState;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.medication.MedicationDispenseTime;
import jct.pillorganizer.repo.DeviceEventRepository;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceScheduleRepository;
import jct.pillorganizer.repo.DeviceStateRepository;
import jct.pillorganizer.repo.DeviceUserRepository;
import lombok.extern.flogger.Flogger;

/**
 * Business logic for dealing with device state.
 */
@Flogger
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
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceAuthService deviceAuthService;

    @Inject
    FirmwareService firmwareService;

    /**
     * Creates a `DeviceStateWrapper` for a particular device.
     * 
     * @param device the device to create a wrapper around
     * @return a DeviceStateWrapper that operates on a particular device
     */
    public DeviceStateWrapper wrapperOf(Device device, DeviceUser deviceUser) {
        return new DeviceStateWrapper(deviceRepository, deviceScheduleRepository,
                deviceStateRepository, deviceEventRepository, firmwareService, device, deviceUser);
    }

    /**
     * Creates a DeviceStateWrapper for device sync operations.
     * 
     * @return DeviceStateWrapper ready for sync operations
     * @throws Problem if the device or device user relationship doesn't exist or the device is not provisioned
     */
    @Transactional
    public DeviceStateWrapper getDeviceStateWrapperForDeviceSync() {
        Device device = deviceAuthService.getDevice();
        
        DeviceProvision deviceProvision = device.getCurrentProvision();
        if (deviceProvision == null) {
            throw Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.PRECONDITION_FAILED))
                .withTitle("Device not provisioned")
                .withDetail("Device must be provisioned before syncing")
                .build();
        }
        
        long userId = deviceProvision.getUserID();
        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalseOrThrow(userId, device.getId());
        
        return wrapperOf(device, deviceUser);
    }

    /**
     * Packs the status field of every bin state of a device into a single long.
     * This is an optimization trip so that
     * we don't need to store or serialize the status of every bin into an array of
     * integers. Instead we only need one
     * integer.
     * 
     * @param deviceUser device to calculate the state flag on
     * @return a long representing the packed status of every bin state
     */
    public long calculateStateFlags(DeviceUser deviceUser) {
        long flags = 0;
        List<DeviceState> bins = deviceStateRepository.findByDeviceUser(deviceUser);

        for (DeviceState bin : bins) {
            long statusInt = bin.getBinStatus().getIntValue();
            long binNum = bin.getId().getBinID();
            flags |= (statusInt << (4 * binNum));
        }
        return flags;
    }

    private String convertInstantToString(Instant instant, String tz) {
        ZoneId desiredZone = ZoneId.of(tz);
        ZonedDateTime zonedDateTime = instant.atZone(desiredZone);
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm");
        return zonedDateTime.format(formatter);
    }

    /**
     * Builds a compact representation of a device's state around a particular date.
     * Only information relevant to that
     * date is included in the resultant list.
     * 
     * @param device device to build the dose period for
     * @param date   the date that all dose periods should be on
     * @return a list of DosePeriodDTO objects, representing a time on the specified
     *         date that medication is taken
     */
    @Transactional
    public List<DosePeriodDTO> buildDosePeriod(Device device, DeviceUser deviceUser, LocalDate date) {
        ZonedDateTime startOfDay = date.atStartOfDay(device.getTimeZone());
        ZonedDateTime endOfDay = startOfDay.plusDays(1);

        List<DeviceState> states = deviceStateRepository.findByDeviceAndTimeBetween(deviceUser, startOfDay.toEpochSecond(),
                endOfDay.toEpochSecond());

        List<DosePeriodDTO> dtos = new ArrayList<>(states.size());
        for (DeviceState state : states) {
            List<Long> medicationIDs = state.getDispenseTime().getMedications()
                    .stream()
                    .map(MedicationDispenseTime::getMedicationID)
                    .toList();

            Optional<DeviceEvent> event = deviceEventRepository
                    .findFirstByDeviceUserIdAndBinIdAndEventTypeClosedAndTsIsAfterOrderByTsAsc(
                            deviceUser.getId(), state.getId().getBinID(), EventType.CLOSED,
                            Instant.ofEpochSecond(startOfDay.toEpochSecond()));
            String takenAtTime = null;

            if (event.isPresent()) {
                DeviceEvent deviceEvent = event.get();
                String formattedTime = convertInstantToString(deviceEvent.getTs(), device.getBaseTZ());
                takenAtTime = formattedTime;
            }

            dtos.add(new DosePeriodDTO(
                    (short) state.getId().getBinID(),
                    state.getScheduledTime(),
                    (short) state.getBinStatus().getIntValue(),
                    medicationIDs,
                    takenAtTime));
        }
        return dtos;
    }
}
