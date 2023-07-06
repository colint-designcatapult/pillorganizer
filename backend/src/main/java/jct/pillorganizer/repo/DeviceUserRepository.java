package jct.pillorganizer.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.dto.DeviceUserDTO;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.user.BaseUser;

import java.util.Optional;
import java.util.Set;

@Repository
public interface DeviceUserRepository extends CrudRepository<DeviceUser, Long> {

    int countByUserIDAndDeviceID(long user, long device);
    int countByUserAndDevice(BaseUser user, Device device);

    /*@Query(nativeQuery = true, readOnly = false, value = "INSERT INTO device_user (id, device_id, user_id, primary_user, owner)" +
            " VALUES (nextval('device_user_seq'), :user, :device, :primaryUser, :owner) ON CONFLICT (device_id, user_id) DO NOTHING")
    void saveOrUpdate(long user, long device, boolean primaryUser, boolean owner);*/

    void update(@Id Long id, String notificationToken);

    void updateNotificationTokenById(@Id Long id, @Nullable String notificationToken);


    DeviceUser findByUserIDAndDeviceID(long user, long device);

    Optional<Device> retrieveDeviceByUserIDAndDeviceID(long userID, long deviceID);

    @Query("select new jct.pillorganizer.dto.DeviceUserDTO(du.id, du.deviceID, d.deviceClass, d.customName, d.lastSync, d.serialNo, du.primaryUser, du.owner, du.notificationToken is not null, d.baseTZ) from device_user du join du.device d where du.userID = :user")
    Set<DeviceUserDTO> findByUserID(long user);

    @Query("select new jct.pillorganizer.dto.DeviceUserDTO(du.id, du.deviceID, d.deviceClass, d.customName, d.lastSync, d.serialNo, du.primaryUser, du.owner, du.notificationToken is not null, d.baseTZ) from device_user du join du.device d where du.userID = :user and du.deviceID = :device")
    Optional<DeviceUserDTO> retrieveByUserIDAndDeviceID(long user, long device);


}
