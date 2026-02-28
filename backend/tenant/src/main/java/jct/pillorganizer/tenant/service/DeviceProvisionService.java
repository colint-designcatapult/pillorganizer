package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.user.User;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class DeviceProvisionService {

    @Inject
    DeviceUserService deviceUserService;
    @Inject
    DeviceService deviceService;

    @Transactional
    public Device provision(User user, String deviceID, String serialNo, String claimToken) {
        log.atInfo().log("Provisioning %s to %s using %s", deviceID, user.getId(), claimToken);
        Device device = deviceService.create(deviceID, serialNo, claimToken);
        deviceUserService.addUserToDevice(user, device, true);
        return device;
    }

}
