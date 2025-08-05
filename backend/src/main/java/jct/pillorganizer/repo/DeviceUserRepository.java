package jct.pillorganizer.repo;

import java.util.Optional;
import java.util.Set;

import org.zalando.problem.Problem;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import io.micronaut.http.HttpStatus;
import io.micronaut.problem.HttpStatusType;
import jct.pillorganizer.dto.DeviceUserDTO;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.user.BaseUser;

@Repository
public interface DeviceUserRepository extends CrudRepository<DeviceUser, Long> {

    int countByUserIDAndDeviceIDAndDeletedFalse(long user, long device);
    int countByUserAndDeviceAndDeletedFalse(BaseUser user, Device device);
    int countByUserIDAndDeviceIDAndOwnerTrueAndDeletedFalse(long user, long device);
    
    Optional<DeviceUser> findByDeviceIDAndOwnerTrueAndDeletedFalse(long deviceID);

    /*@Query(nativeQuery = true, readOnly = false, value = "INSERT INTO device_user (id, device_id, user_id, primary_user, owner)" +
            " VALUES (nextval('device_user_seq'), :user, :device, :primaryUser, :owner) ON CONFLICT (device_id, user_id) DO NOTHING")
    void saveOrUpdate(long user, long device, boolean primaryUser, boolean owner);*/

    void update(@Id Long id, String notificationToken);

    void updateNotificationTokenById(@Id Long id, @Nullable String notificationToken);


    Optional<DeviceUser> findByUserIDAndDeviceIDAndDeletedFalse(long user, long device);
    
    default DeviceUser findByUserIDAndDeviceIDAndDeletedFalseOrThrow(long user, long device) {
        return findByUserIDAndDeviceIDAndDeletedFalse(user, device)
                .orElseThrow(() -> Problem.builder()
                        .withStatus(new HttpStatusType(HttpStatus.PRECONDITION_FAILED))
                        .withTitle("Device not provisioned")
                        .withDetail("Device must be fully provisioned before this operation can be performed")
                        .build());
    }

    Optional<Device> retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(long userID, long deviceID);

    @Query("select new jct.pillorganizer.dto.DeviceUserDTO(du.id, du.deviceID, d.deviceClass, d.customName, d.lastSync, d.serialNo, du.primaryUser, du.owner, du.notificationToken is not null, d.baseTZ) from device_user du join du.device d where du.userID = :user AND du.deleted = false")
    Set<DeviceUserDTO> findByUserID(long user);

    @Query("select new jct.pillorganizer.dto.DeviceUserDTO(du.id, du.deviceID, d.deviceClass, d.customName, d.lastSync, d.serialNo, du.primaryUser, du.owner, du.notificationToken is not null, d.baseTZ) from device_user du join du.device d where du.userID = :user and du.deviceID = :device and du.deleted = false")
    Optional<DeviceUserDTO> retrieveByUserIDAndDeviceID(long user, long device);

    @Query("UPDATE device_user du SET du.deleted = true WHERE du.userID = :userId AND du.deviceID= :deviceId")
    void softDelete(Long userId, Long deviceId);
}
