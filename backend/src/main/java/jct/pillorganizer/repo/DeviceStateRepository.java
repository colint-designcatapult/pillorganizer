package jct.pillorganizer.repo;

import io.micronaut.data.annotation.*;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.dto.DeviceNotificationDetails;
import jct.pillorganizer.model.device.*;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;

import javax.persistence.OrderBy;
import java.util.List;

@Repository
public interface DeviceStateRepository extends JpaRepository<DeviceState, DeviceBinId> {

    @OrderBy("id.bin DESC")
    List<DeviceState> findByDevice(Device device);

    @Query("from device_state where device.id = :id")
    @Join(value = "assoc_event_id", type = Join.Type.FETCH)
    List<DeviceState> findByDeviceID(long id);

    @Query("from device_state s where device.id = :id")
    @Join(value = "assoc_event_id", type = Join.Type.FETCH)
    List<DeviceState> findByDeviceIDWithSchedule(long id);

    @Query("from device_state s where s.device = :d and s.scheduledTime >= :start and s.scheduledTime < :end")
    List<DeviceState> findByDeviceAndTimeBetween(Device d, long start, long end);


    void deleteByDevice(Device device);

    void update(@Id DeviceBinId id, @Version Long version, long scheduledTime, BinStatus binStatus);
    void update(@Id DeviceBinId id, @Version Long version, BinStatus binStatus);
    void update(@Id DeviceBinId id, @Version Long version, BinStatus binStatus, DeviceEvent event);
    void update(@Id DeviceBinId id, @Version Long version, DeviceBaseDispenseTime dispenseTime);

    @Query( value = "update device_state set scheduled_time = 0, assoc_event_id = null, bin_status = 0 where device_id = :device", nativeQuery = true)
    void updateResetState(long device);

    @Query( value = "with updated_device_ids as (update device_state set bin_status = 4 where bin_status = 3 and scheduled_time <= :now returning device_id)\n" +
            "select d.custom_name as deviceName, du.notification_token as notificationToken, du.device_id as deviceID " +
            "from updated_device_ids " +
            "left join device_user du on updated_device_ids.device_id = du.device_id " +
            "left join device d on updated_device_ids.device_id = du.device_id", nativeQuery = true)
    List<DeviceNotificationDetails> updatePendingToTakeNow(long now);

    @Query( value = "with updated_device_ids as (update device_state set bin_status = 2 where bin_status = 4 and scheduled_time < :threshold returning device_id)\n" +
            "select d.custom_name as deviceName, du.notification_token as notificationToken, du.device_id as deviceID from updated_device_ids left join device_user du on updated_device_ids.device_id = du.device_id left join device d on updated_device_ids.device_id = du.device_id", nativeQuery = true)
    List<DeviceNotificationDetails> updateTakeNowToMissed(long threshold);


    @Query(value = "with updated_device_ids as (update device_state\n" +
            "                                set bin_status = :setTo\n" +
            "                                where bin_status = :where and scheduled_time <= :threshold returning device_id)\n" +
            "select d.custom_name as deviceName, du.notification_token as notificationToken, du.device_id as deviceID\n" +
            "from updated_device_ids\n" +
            "         left join device_user du on updated_device_ids.device_id = du.device_id\n" +
            "         left join device d on d.id = du.device_id\n" +
            "where notification_token is not null\n", nativeQuery = true)
    List<DeviceNotificationDetails> updateBinStateFromTime(long setTo, long where, long threshold);

}
