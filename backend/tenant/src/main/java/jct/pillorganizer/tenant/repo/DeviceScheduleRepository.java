package jct.pillorganizer.tenant.repo;

import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;

import java.util.List;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceScheduleRepository extends CrudRepository<DeviceSchedule, String> {

    List<DeviceSchedule> findByDeviceId(String deviceId);

    List<DeviceSchedule> findByDeviceIdAndStatus(String deviceId, ScheduleStatus status);
}
