package jct.pillorganizer.device;

import jct.pillorganizer.model.EventType;
import jct.pillorganizer.model.device.DayOfWeek;
import jct.pillorganizer.model.device.*;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;
import jct.pillorganizer.proto.Pill;
import jct.pillorganizer.repo.DeviceEventRepository;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceScheduleRepository;
import jct.pillorganizer.repo.DeviceStateRepository;
import jct.pillorganizer.service.FirmwareService;
import lombok.extern.flogger.Flogger;

import javax.annotation.Nullable;
import javax.transaction.Transactional;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;
import java.util.zip.CRC32;

/**
 * Device state business logic.
 */
@Flogger
public class DeviceStateWrapper {

    private static final int EVENT_CTR_DELTA_THRESHOLD = 28;
    private static final int BATTERY_MUX_CHANNEL = 14;
    private static final int BATTERY_OFFSET = 200;
    private static final double VOLTAGE_RATIO = 1.4;
    private static final int BATTERY_MAX_ADC = 3700;
    private static final double BATTERY_MAX_CAL = 3700.0;

    private final DeviceScheduleRepository scheduleRepository;
    private final DeviceStateRepository stateRepository;
    private final DeviceRepository deviceRepository;
    private final DeviceEventRepository deviceEventRepository;
    private final FirmwareService firmwareService;
    private final Device device;

    private List<DeviceSchedule> _schedule = null;
    private List<DeviceState> _stateList = null;
    private List<DeviceState> _stateChrono = null;

    public DeviceStateWrapper(DeviceRepository deviceRepository, DeviceScheduleRepository scheduleRepository,
            DeviceStateRepository stateRepository, DeviceEventRepository deviceEventRepository,
            FirmwareService firmwareService, Device device) {
        this.deviceRepository = deviceRepository;
        this.scheduleRepository = scheduleRepository;
        this.stateRepository = stateRepository;
        this.deviceEventRepository = deviceEventRepository;
        this.firmwareService = firmwareService;
        this.device = device;
    }

    private void lazyUpdateBin(DeviceState state, BinStatus status, long timestamp) {
        if (state.getScheduledTime() != timestamp || !status.equals(state.getBinStatus())) {
            state.setBinStatus(status);
            state.setScheduledTime(timestamp);
            stateRepository.update(state.getId(), state.getVersion(), timestamp, status);
        }
    }

    private void lazyUpdateBinDispenseTime(DeviceState state, DeviceBaseDispenseTime dispenseTime) {
        if (state.getDispenseTime() == null || !Objects.equals(state.getDispenseTime().getId(), dispenseTime.getId())) {
            if (dispenseTime != null) {
                state.setDispenseTime(dispenseTime);
                stateRepository.update(state.getId(), state.getVersion(), dispenseTime);
            }
        }
    }

    /**
     * Get the device's bin states sorted by scheduled time, starting with the
     * oldest
     *
     * @return list of bin states in chronological order
     */
    public List<DeviceState> getChronologicalState() {
        if (_stateChrono == null) {
            _stateChrono = getState()
                    .stream()
                    .sorted(Comparator.comparing(DeviceState::getScheduledTime))
                    .toList();
        }
        return _stateChrono;
    }

    /**
     * Get the previously scheduled bin relative to another bin.
     *
     * @param state bin to get the previous scheduled bin for
     * @return the previously scheduled bin, or empty if no previously scheduled bin
     */
    public Optional<DeviceState> previousScheduled(DeviceState state) {
        List<DeviceState> c = getChronologicalState();
        int idx = c.indexOf(state);
        if (idx > 0)
            return Optional.of(c.get(idx - 1));
        return Optional.empty();
    }

    /**
     * Gets the next scheduled bin relative to another bin.
     *
     * @param state bin to get the next scheduled bi nfor
     * @return the next scheduled bin, or empty if no next scheduled bin
     */
    public Optional<DeviceState> nextScheduled(DeviceState state) {
        List<DeviceState> c = getChronologicalState();
        int idx = c.indexOf(state);
        if (idx > 0 && idx < c.size() - 1)
            return Optional.of(c.get(idx + 1));
        return Optional.empty();
    }

    /**
     * Processes an event sourced from a device, with all state effects.
     *
     * @param event event to process
     */
    public void handleBinEvent(DeviceEvent event) {
        DeviceState state = getState().get(event.getBin());

        if (EventType.CLOSED.equals(event.getEventType())) {
            switch (state.getBinStatus()) {
                case PENDING:
                case MISSED:
                    //
                    // Handles cases where a bin is opened outside its scheduled time.
                    // We consider it "taken" if it is opened between the previous and next
                    // scheduled doses
                    //

                    Optional<DeviceState> prevOpt = previousScheduled(state);
                    Optional<DeviceState> nextOpt = nextScheduled(state);

                    LocalDateTime ldt = LocalDateTime.ofInstant(event.getTs(), ZoneId.of("UTC"));

                    if (prevOpt.isPresent() && nextOpt.isPresent()) {
                        if (ldt.isAfter(
                                LocalDateTime.ofEpochSecond(nextOpt.get().getScheduledTime(), 0, ZoneOffset.UTC))
                                || ldt.isBefore(LocalDateTime.ofEpochSecond(prevOpt.get().getScheduledTime(), 0,
                                        ZoneOffset.UTC)))
                            break;
                    } else if (prevOpt.isPresent()) {
                        if (ldt.isBefore(
                                LocalDateTime.ofEpochSecond(prevOpt.get().getScheduledTime(), 0, ZoneOffset.UTC)))
                            break;
                    } else if (nextOpt.isPresent()) {
                        if (ldt.isAfter(
                                LocalDateTime.ofEpochSecond(nextOpt.get().getScheduledTime(), 0, ZoneOffset.UTC)))
                            break;
                    }
                case TAKE_NOW:
                    stateRepository.update(state.getId(), state.getVersion(), BinStatus.TAKEN, event);
                    state.setBinStatus(BinStatus.TAKEN);
                    break;
            }
        } else if (EventType.MISSED.equals(event.getEventType())) {

            stateRepository.update(state.getId(), state.getVersion(), BinStatus.MISSED, event);
            state.setBinStatus(BinStatus.MISSED);
        }
    }

    /**
     * Override the bin state stored in the database with a Protobuf-encoded state
     * structure.
     *
     * @param state the state to override server state with
     */
    @Transactional
    public void updateState(Pill.AllBinsState state) {
        List<DeviceState> states = getState();
        for (int binID = 0; binID < state.getBinsCount(); binID++) {
            DeviceState curState = states.get(binID);
            Pill.BinState binState = state.getBins(binID);
            lazyUpdateBin(curState, BinStatus.fromProtobuf(binState.getStatus()), binState.getScheduledTime());
        }
        updateStateHash();

    }

    /**
     * Reload the pills in a device by resetting the state's schedule.
     */
    @Transactional
    public void reload() {
        // Clear current state
        stateRepository.updateResetState(device.getId());
        rebuildStateSchedule();
    }

    /**
     * Performs a two-way device sync according to the business rules.
     *
     * @param syncRequest protobuf sync request structure containing the device's
     *                    state and events to process
     * @return sync response structure the device should process and use to override
     *         its internal state with
     */
    @Transactional
    public Pill.SyncResponse sync(Pill.SyncRequest syncRequest, boolean isBluetooth) {
        Pill.SyncResponse.Builder builder = Pill.SyncResponse.newBuilder();

        // Load all events
        long ctr = device.getEventCounter();
        Instant timeStamp = Instant.ofEpochSecond(0);
        for (Pill.RecordedEvent recEv : syncRequest.getEventsList()) {
            DeviceEvent ev = new DeviceEvent();
            ev.setDevice(device);
            ev.setTs(Instant.ofEpochSecond(recEv.getTimestamp()));
            ev.setEventType(EventType.fromProtobuf(recEv.getType()));

            if (recEv.hasBin())
                ev.setBin(recEv.getBin());
            else
                ev.setBin(-1);

            deviceEventRepository.save(ev);
            handleBinEvent(ev);
            timeStamp = Instant.ofEpochSecond(recEv.getTimestamp());
            log.atInfo().log("Device initiated event, bin: %d event: %s", recEv.getBin(),
                    EventType.fromProtobuf(recEv.getType()).toString());
            ctr++;
        }

        if (ctr != device.getEventCounter()) {
            device.setEventCounter(ctr);
            deviceRepository.update(device.getId(), device.getVersion(), calculateStateHash(), ctr);
        }

        long deltaCtr = syncRequest.getEventCtr() - device.getEventCounter();
        if (deltaCtr > EVENT_CTR_DELTA_THRESHOLD
                || (isBluetooth && Timestamp.from(timeStamp).after(device.getLastSync()))) {
            log.atInfo().log("Delta counter past threshold or is on bluetooth accepting client state");
            // Server is too far out of date for us to catch up, so we just accept the
            // client state as truth
            updateState(syncRequest.getBinState());
        } else {
            // Send the device the state that we have
            // if(device.getStateHash() != syncRequest.getStateHash()) {
            builder.setBinState(buildStateProtobuf());
            // }
        }

        builder.addAllSchedule(buildBinSchedule());

        deviceRepository.updateLastSyncAndIpv4AndIpv6AndBatteryAndChargingAndEngrData(
                device.getId(),
                device.getVersion(),
                Timestamp.from(Instant.now()),
                syncRequest.hasIpv4() ? syncRequest.getIpv4() : null,
                syncRequest.hasIpv6() ? syncRequest.getIpv6().toByteArray() : null,
                getBatteryLevel(syncRequest).orElse(null),
                getBatteryCharging(syncRequest),
                getEngineeringData(syncRequest).orElse(null));

        builder.setLatestFirmware(firmwareService.getLatestVersion());

        return builder.build();
    }

    /**
     * Update the state hash in the database to match the current state stored in
     * this object.
     */
    @Transactional
    public void updateStateHash() {
        long hash = calculateStateHash();
        deviceRepository.update(device.getId(), device.getVersion(), calculateStateHash(), device.getEventCounter());
        this.device.setStateHash(hash);
    }

    private long calculateStateHash() {
        List<DeviceState> stateList = getState();
        CRC32 crc = new CRC32();

        ByteBuffer bb = ByteBuffer.allocate(9).order(ByteOrder.LITTLE_ENDIAN);
        for (DeviceState st : stateList) {
            bb.put((byte) st.getBinStatus().getIntValue());
            bb.putLong(st.getScheduledTime());
            byte[] arr = bb.array();
            crc.update(arr);
            bb.rewind();
        }

        return crc.getValue();
    }

    /**
     * Serializes the device's state.
     *
     * @return protobuf AllBinsState of the current device's state
     */
    public Pill.AllBinsState.Builder buildStateProtobuf() {
        List<DeviceState> stateList = getState();
        Pill.AllBinsState.Builder builder = Pill.AllBinsState.newBuilder();

        for (DeviceState state : stateList) {
            Pill.BinState.Builder b = Pill.BinState.newBuilder();

            b.setStatusValue(state.getBinStatus().getIntValue());
            b.setScheduledTime(state.getScheduledTime());

            builder.addBins(b);
        }

        return builder;
    }

    /**
     * Serializes the device's schedule.
     *
     * @return protobuf BinSchedule of the current device's dispense schedule
     * @deprecated use schedule strategy directly
     */
    public Iterable<? extends Pill.BinSchedule> buildBinSchedule() {
        List<Pill.BinSchedule> result = new ArrayList<>(device.getDeviceClass().getBinCount());

        for (DeviceSchedule schedule : getDeviceSchedule()) {
            result.add(
                    Pill.BinSchedule.newBuilder()
                            .setDayOfWeekValue(schedule.getDayOfWeek().getIntValue())
                            .setSecondsFrom00(schedule.getSecondsFrom00())
                            .build());
        }

        return result;
    }

    /**
     * Initialize the state and schedule of a new device. If a device already had a
     * state or schedule, it will be
     * preserved. The initial state has all bins disabled and an empty schedule.
     *
     * @param initialState optional state to initialize the device with
     */
    @Transactional
    public void initialize(@Nullable Pill.AllBinsState initialState) {
        buildInitialSchedule();
        buildInitialState(initialState);
    }

    /**
     * Initialize the state of a new device. If a device already has a state, it
     * will be preserved. The freshly
     * initialized state will have all bins disabled.
     *
     * @param initialState unused
     */
    @Transactional
    public void buildInitialState(@Nullable Pill.AllBinsState initialState) {
        if (initialState != null && initialState.isInitialized() && initialState.getBinsCount() > 0) {
            // todo
        } else {
            // Delete all state entities
            stateRepository.deleteByDevice(device);

            int binCount = device.getDeviceClass().getBinCount();
            _stateList = new ArrayList<>(binCount);

            // Create state entity for each bin of this device
            for (int bin = 0; bin < binCount; bin++) {
                DeviceState state = new DeviceState();
                state.setId(new DeviceBinId(device.getId(), bin));
                state.setBinStatus(BinStatus.DISABLED);
                state.setScheduledTime(0);
                _stateList.add(bin, stateRepository.save(state));
            }

            rebuildStateSchedule();

        }
        updateStateHash();
    }

    /**
     * Initializes the schedule of a new device, if a schedule doesn't exist. The
     * freshly initialized schedule will
     * have all bins disabled.
     */
    @Transactional
    public void buildInitialSchedule() {
        // Only create a schedule if one doesn't exist
        int binCount = device.getDeviceClass().getBinCount();
        if (getDeviceSchedule().size() == 0) {
            _schedule = new ArrayList<>(binCount);

            for (int bin = 0; bin < binCount; bin++) {
                DeviceSchedule schedule = new DeviceSchedule();
                schedule.setId(new DeviceBinId(device.getId(), bin));

                schedule.setDayOfWeek(DayOfWeek.DISABLED);
                schedule.setSecondsFrom00(0);

                _schedule.add(bin, scheduleRepository.save(schedule));
            }
        }
    }

    /**
     * Synchronizes the device's state scheduled times with the device's schedule.
     * Used, for example, if the schedule
     * is changed in the middle of the week.
     */
    @Transactional
    public void rebuildStateSchedule() {
        ZoneOffset tz = device.getTimeZone();
        LocalDate ld = LocalDate.now(tz);
        OffsetDateTime ldt = OffsetDateTime.now(tz);

        // Normalize day of week to start the week on Monday
        int day = Math.floorMod((ld.getDayOfWeek().getValue() - 1), 7);
        OffsetDateTime base = ld
                .minusDays(day)
                .atTime(0, 0, 0, 0)
                .atOffset(tz);

        List<DeviceState> states = getState();
        for (DeviceSchedule schedule : getDeviceSchedule()) {
            OffsetDateTime dispenseTime = base
                    .plusDays(schedule.getDayOfWeek().getIntValue())
                    .plusSeconds(schedule.getSecondsFrom00());
            LocalDateTime dispenseLDT = dispenseTime.atZoneSameInstant(ZoneOffset.UTC).toLocalDateTime();

            DeviceState state = states.get(schedule.getBinID());

            BinStatus status = state.getBinStatus();

            if (DayOfWeek.DISABLED.equals(schedule.getDayOfWeek())) {
                // If this bin is scheduled to be disabled,
                lazyUpdateBin(state, BinStatus.DISABLED, dispenseLDT.toEpochSecond(ZoneOffset.UTC));
            } else if (BinStatus.TAKEN.equals(status)) {
                // Never rebuild a taken bin
            } else if (BinStatus.MISSED.equals(status) || BinStatus.PENDING.equals(status)
                    || BinStatus.TAKE_NOW.equals(status) || BinStatus.DISABLED.equals(status)) {
                OffsetDateTime lateThresholdTime = dispenseTime.plusMinutes(10);

                // Only rebuild a missed dose if the scheduled time is today or after now
                if (lateThresholdTime.isAfter(ldt)) {
                    lazyUpdateBin(state, BinStatus.PENDING, dispenseLDT.toEpochSecond(ZoneOffset.UTC));
                } else if (lateThresholdTime.isBefore(ldt) && dispenseTime.isAfter(ldt)) {
                    lazyUpdateBin(state, BinStatus.TAKE_NOW, dispenseLDT.toEpochSecond(ZoneOffset.UTC));
                } else if (BinStatus.DISABLED.equals(status) && day == schedule.getDayOfWeek().getIntValue()) {
                    lazyUpdateBin(state, BinStatus.DISABLED, dispenseLDT.toEpochSecond(ZoneOffset.UTC));
                }
                lazyUpdateBinDispenseTime(state, schedule.getDispenseTime());
            }
        }

    }

    /**
     * Gets the device schedule.
     *
     * @return all device bin schedules, in ascending order of bin ID
     */
    public List<DeviceSchedule> getDeviceSchedule() {
        if (_schedule == null) {
            _schedule = scheduleRepository.findByDevice(device);
            _schedule.sort(Comparator.comparingInt(c -> c.getId().getBinID()));
        }
        return _schedule;
    }

    private void validateOrRepairState() {
        List<DeviceState> state = _stateList;

        // Make sure there are exactly the number of state entries as there are bins
        int binCount = device.getDeviceClass().getBinCount();

        if (state.size() != binCount) {
            // todo: rebuild
        }

        DeviceState first = state.get(0);
        DeviceState last = state.get(binCount - 1);

        if (first.getId().getBinID() != 0 || last.getId().getBinID() != (binCount - 1)) {
            // todo: rebuild
        }
    }

    /**
     * Gets the device's bin states.
     *
     * @return all device bin states, in ascending order of bin ID.
     */
    public List<DeviceState> getState() {
        if (_stateList == null) {
            _stateList = stateRepository.findByDevice(device);
            _stateList.sort(Comparator.comparingInt(c -> c.getId().getBinID()));
            validateOrRepairState();
        }
        return _stateList;
    }

    /**
     * Gets the device's battery level.
     * 
     * @return the device battery level if engineering data is available.
     */
    private Optional<Integer> getBatteryLevel(Pill.SyncRequest syncRequest) {
        if (syncRequest.hasEngrData()) {
            return Optional.of((int) syncRequest.getEngrData().getVbatMeas());
        } else {
            return Optional.empty();
        }
    }

    /**
     * Gets the device's battery charging info.
     * 
     * @return the device battery charging info if engineering data is available.
     */
    private Boolean getBatteryCharging(Pill.SyncRequest syncRequest) {
        if (syncRequest.hasEngrData()) {
            return syncRequest.getEngrData().getVbatScaled() == 1.0;
        } else {
            return false;
        }
    }

    /**
     * Gets the device's engr_data.
     *
     * @return the device engineering data if available.
     */
    private Optional<String> getEngineeringData(Pill.SyncRequest syncRequest) {
        if (syncRequest.hasEngrData()) {
            return Optional.of("vbatMeas:" +syncRequest.getEngrData().getVbatMeas());
        } else {
            return Optional.empty();
        }
    }

}
