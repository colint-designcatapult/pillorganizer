package jct.pillorganizer.tenant.repo;

import java.util.List;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.tenant.model.device.DayOfWeek;
import jct.pillorganizer.tenant.model.device.DeviceBinId;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.schedule.DeviceBaseDispenseTime;

@Repository
public interface DeviceScheduleRepository extends JpaRepository<DeviceSchedule, DeviceBinId> {
    @Nullable
    @Query("SELECT ds FROM device_schedule ds WHERE ds.deviceUser = :deviceUser")
    List<DeviceSchedule> findByDeviceUser(DeviceUser deviceUser);

    int update(@Id DeviceBinId id, DayOfWeek dayOfWeek, int secondsFrom00, @Nullable DeviceBaseDispenseTime dispenseTime);
}
