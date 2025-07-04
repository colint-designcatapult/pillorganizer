package jct.pillorganizer.service;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Optional;

import javax.transaction.Transactional;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.auth.DeviceAuthService;
import jct.pillorganizer.device.DeviceStateWrapper;
import jct.pillorganizer.exceptions.AccessForbiddenException;
import jct.pillorganizer.exceptions.DeviceProvisionExpiredException;
import jct.pillorganizer.exceptions.DeviceProvisionNotFoundException;
import jct.pillorganizer.exceptions.SsidMismatchException;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceClass;
import jct.pillorganizer.model.device.DeviceProvision;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.proto.Pill;
import jct.pillorganizer.repo.DeviceProvisionRepository;
import jct.pillorganizer.repo.DeviceRepository;
import jct.pillorganizer.repo.DeviceUserRepository;
import lombok.extern.flogger.Flogger;

/**
 * Business logic for dealing with device provisioning.
 */
@Singleton
@Flogger
public class DeviceProvisionService {

    @Inject
    DeviceService deviceService;

    @Inject
    DeviceProvisionRepository deviceProvisionRepository;

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceAuthService deviceAuthService;

    @Inject
    DeviceStateService deviceStateService;

    @Inject
    AuthService authService;

    @Inject
    DeviceUserService deviceUserService;

    @Inject
    FirmwareService firmwareService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    private byte[] generateOobKey() throws NoSuchAlgorithmException {
        byte[] key = new byte[16];
        SecureRandom.getInstanceStrong().nextBytes(key);
        return key;
    }

    /**
     * Initiates the provisioning flow. If no Device record exists with the
     * specified serial number, a new Device is
     * created. The serial number must be accurate otherwise provisioning will
     * eventually fail. The timezone is
     * written into the Device's timezone record and should be set to the user's
     * timezone. A successful call to this
     * method will invalidate all previous provision attempts (but will keep an
     * existing device provisioned until
     * completion).
     * Provisioning is initiated by the app.
     * 
     * @param serialNo    the serial number of the device to provision
     * @param deviceClass the type of device (device class) of the device to
     *                    provision
     * @param tzLocation  timezone location string (e.g., America/Detroit) to base
     *                    the device's time on
     * @return initialized provisioning record
     */
    @Transactional
    public DeviceProvision startProvisioning(long serialNo, DeviceClass deviceClass, String tzLocation) {
        Device device = deviceService.findOrCreateDevice(serialNo, deviceClass);

        // Deactivate all previous `device_provision` entities
        deviceProvisionRepository.updateActiveByDeviceAndActive(device, true, false);

        // Fill in provision record
        DeviceProvision deviceProvision = new DeviceProvision();
        deviceProvision.setDevice(device);
        deviceProvision.setActive(true);
        deviceProvision.setUserID(authService.getUserID());
        deviceProvision.setTimezone(tzLocation);

        // Generate OOB key
        try {
            deviceProvision.setOobKey(generateOobKey());
        } catch (NoSuchAlgorithmException ex) {
            throw new RuntimeException(ex);
        }

        // Persist provision record
        DeviceProvision saved = deviceProvisionRepository.save(deviceProvision);

        // Update Device so its provision record points to this one
        deviceRepository.update(device.getId(), device.getVersion(), saved);
        return saved;
    }

    /**
     * Check if a device's provisioning process has completed. The parameters must
     * exactly match what was provided
     * during the provisioning process otherwise this method will fail.
     * 
     * @param provID the ID of the provision record to check
     * @param sn     serial number of the device
     * @param ssid   SSID of the WiFi network the device was provisioned for
     * @return the Device record, if provisioning is finished & successful
     * @throws org.zalando.problem.ThrowableProblem if provisioning has not
     *                                              finished, was not successful, or
     *                                              the
     *                                              parameters were invalid.
     */
    @Transactional
    public Device checkProvisioning(long provID, long sn, String ssid) {
        Optional<DeviceProvision> provOpt = deviceProvisionRepository.findByIdAndDevice_SerialNo(provID, sn);
        if (provOpt.isEmpty())
            throw new DeviceProvisionNotFoundException("Device provisioning not found");
        DeviceProvision prov = provOpt.get();
        // Check if the user is allowed to access this provision record
        if (prov.getUserID() != authService.getUserID()) {
            throw new AccessForbiddenException("User does not have access to this provision record");
        }

        // Check if the provided provision ID and the specified device's current
        // provision ID match
        if (!Objects.equals(prov.getId(), prov.getDevice().getCurrentProvision().getId()))
            throw new DeviceProvisionExpiredException("Device provision expired");

        // Ensure device got provisioned on the correct WiFi network
        if (ssid.equalsIgnoreCase(prov.getSsid())) {
            return prov.getDevice();
        }

        // If we hit this point, it could mean EITHER WiFi SSID didn't match OR
        // provisioning isn't complete yet
        // We currently have no way to tell, we should add a field to DeviceProvision
        throw new SsidMismatchException("SSID does not match");
    }

    /**
     * Finish provisioning, indicating that the device has successfully connected to
     * WiFi (thus, this is called from
     * the device itself).
     * 
     * @param req protobuf structure with information about provisioning
     * @return device sync response
     */
    @Transactional
    public Pill.SyncResponse completeProvisioning(Pill.DeviceProvisionRequest req) {
        Device device = deviceAuthService.getDevice();
        DeviceProvision provision = device.getCurrentProvision();
        long userId = provision.getUserID();

        // Update timezone
        deviceRepository.updateBaseTZById(device.getId(), provision.getTimezone());

        // Update provision record with SSID/BSSID
        byte[] bssid = req.getBssid().toByteArray();
        String bssidHex = HexFormat.of().formatHex(bssid);
        deviceProvisionRepository.update(provision.getId(), provision.getVersion(), bssidHex, req.getSsid());

        // Add user to device
        deviceUserService.addUserToDevice(userId, device.getId(), true, false);

        log.atInfo().log("Provisioned device %d with SSID %s on timezone %s", device.getId(), req.getSsid(),
                device.getBaseTZ());

        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalse(userId, device.getId());

        // Initialize the device state
        DeviceStateWrapper wrapper = deviceStateService.wrapperOf(device, deviceUser);
        wrapper.initialize(null);

        // Respond with sync so the pill organizer has the latest data
        return Pill.SyncResponse.newBuilder()
                .setBinState(wrapper.buildStateProtobuf())
                .addAllSchedule(wrapper.buildBinSchedule())
                .setLatestFirmware(firmwareService.getLatestVersion())
                .build();
    }
}
