package jct.pillorganizer.tenant.repo;

import java.util.List;

import jakarta.persistence.OrderBy;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.annotation.Version;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.tenant.dto.DeviceNotificationDetails;
import jct.pillorganizer.tenant.model.device.BinStatus;
import jct.pillorganizer.tenant.model.device.DeviceBinId;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.model.device.DeviceState;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.schedule.DeviceBaseDispenseTime;

@Repository
public interface DeviceStateRepository extends JpaRepository<DeviceState, DeviceBinId> {

    @OrderBy("id.bin DESC")
    List<DeviceState> findByDeviceUser(DeviceUser deviceUser);

    @Query("from device_state s where s.deviceUser = :d and s.scheduledTime >= :start and s.scheduledTime < :end")
    List<DeviceState> findByDeviceAndTimeBetween(DeviceUser d, long start, long end);

    void deleteByDeviceUser(DeviceUser deviceUser);

    void update(@Id DeviceBinId id, @Version Long version, long scheduledTime, BinStatus binStatus);
    void update(@Id DeviceBinId id, @Version Long version, BinStatus binStatus);
    void update(@Id DeviceBinId id, @Version Long version, BinStatus binStatus, DeviceEvent event);
    void update(@Id DeviceBinId id, @Version Long version, DeviceBaseDispenseTime dispenseTime);
    
    @Query("UPDATE device_state SET scheduledTime = :scheduledTime, binStatus = :binStatus, event = null WHERE id = :id AND version = :version")
    void updateAndClearEvent(@Id DeviceBinId id, @Version Long version, long scheduledTime, BinStatus binStatus);

    @Query( value = "update device_state set scheduled_time = 0, assoc_event_id = null, bin_status = 0 where device_user_id = :deviceUser", nativeQuery = true)
    void updateResetState(long deviceUser);

    @Query(value = "with updated_device_ids as (update device_state\n" +
            "                                set bin_status = :setTo\n" +
            "                                where bin_status = :where and scheduled_time <= :threshold returning device_user_id)\n" +
            "select d.custom_name as deviceName, du.notification_token as notificationToken, du.device_id as deviceID\n" +
            "from updated_device_ids\n" +
            "         left join device_user du on updated_device_ids.device_user_id = du.id\n" +
            "         left join device d on d.id = du.device_id\n" +
            "where notification_token is not null\n", nativeQuery = true)
    List<DeviceNotificationDetails> updateBinStateFromTime(long setTo, long where, long threshold);

}
