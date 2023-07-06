package jct.pillorganizer.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.model.device.DayOfWeek;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceBinId;
import jct.pillorganizer.model.device.DeviceSchedule;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;

import java.util.List;

@Repository
public interface DeviceScheduleRepository extends JpaRepository<DeviceSchedule, DeviceBinId> {

    @Query("from device_schedule where device.id = :id")
    List<DeviceSchedule> findByDeviceID(long id);

    List<DeviceSchedule> findByDevice(Device device);

    void deleteByDevice(Device device);

    int update(@Id DeviceBinId id, DayOfWeek dayOfWeek, int secondsFrom00, @Nullable DeviceBaseDispenseTime dispenseTime);

}
