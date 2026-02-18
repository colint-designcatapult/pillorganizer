package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.user.BaseUser;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;

/**
 * Business logic for `DeviceUser` relationships.
 */
@Singleton
public class DeviceUserService {

    @Inject
    DeviceUserRepository repository;


    /**
     * Adds a user to a device.
     * @param userID user ID to add to the device
     * @param deviceID  device ID to add the user to
     * @param owner whether the user has "owner" privileges over the device
     * @param primaryUser whether the user should be marked as the primary user of the device
     */
    public void addUserToDevice(long userID, long deviceID, boolean owner, boolean primaryUser) {
        if(!doesUserBelongToDevice(userID, deviceID)) {
            DeviceUser du = new DeviceUser();
            du.setDeviceID(deviceID);
            du.setUserID(userID);
            du.setPrimaryUser(primaryUser);
            du.setOwner(owner);
            repository.save(du);
        }
    }

    /**
     * Removes the device_user link
     * @param userID the user id
     * @param deviceID the device to remove
     */
    public void removeDeviceFromUser(long userID, long deviceID) {
        if(doesUserBelongToDevice(userID, deviceID)) {
            repository.softDelete(userID, deviceID);
        }
        else {
            throw new IllegalArgumentException("User is not linked to deviceId");
        }
    }

    /**
     * Checks if a user is added to a specific device.
     * @param user the user to test membership
     * @param device the device to see whether the user is related to it or not
     * @return true if the user is related to the device
     */
    public boolean doesUserBelongToDevice(BaseUser user, Device device) {
        return repository.countByUserAndDeviceAndDeletedFalse(user, device) != 0;
    }
    /**
     * Checks if a user is added to a specific device.
     * @param userID the user ID to test membership
     * @param deviceID the device ID to see whether the user is related to it or not
     * @return true if the user is related to the device
     */
    public boolean doesUserBelongToDevice(long userID, long deviceID) {
        return repository.countByUserIDAndDeviceIDAndDeletedFalse(userID, deviceID) != 0;
    }

    /**
     * Checks if a user has access to a device (is related to the device).
     * @param userID the user ID
     * @param deviceID the device ID
     * @return true if the user has access to the device
     */
    public boolean userHasAccessToDevice(long userID, long deviceID) {
        return doesUserBelongToDevice(userID, deviceID);
    }

    /**
     * Checks if a user owns a specific device.
     * @param userID the user ID
     * @param deviceID the device ID
     * @return true if the user owns the device
     */
    public boolean userOwnsDevice(long userID, long deviceID) {
        return repository.countByUserIDAndDeviceIDAndOwnerTrueAndDeletedFalse(userID, deviceID) != 0;
    }
}
