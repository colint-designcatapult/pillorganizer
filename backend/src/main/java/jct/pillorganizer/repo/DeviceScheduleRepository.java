package jct.pillorganizer.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.model.device.*;
import jct.pillorganizer.model.device.schedule.DeviceBaseDispenseTime;

import java.util.List;

@Repository
public interface DeviceScheduleRepository extends JpaRepository<DeviceSchedule, DeviceBinId> {
    @Nullable
    @Query("SELECT ds FROM device_schedule ds WHERE ds.deviceUser = :deviceUser")
    List<DeviceSchedule> findByDeviceUser(DeviceUser deviceUser);

    int update(@Id DeviceBinId id, DayOfWeek dayOfWeek, int secondsFrom00, @Nullable DeviceBaseDispenseTime dispenseTime);

}
