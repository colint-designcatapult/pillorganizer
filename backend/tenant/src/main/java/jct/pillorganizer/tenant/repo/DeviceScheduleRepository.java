package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.NonNull;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.ScheduleStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceScheduleRepository extends CrudRepository<DeviceSchedule, UUID> {

    List<DeviceSchedule> findByDeviceId(String deviceId);

    List<DeviceSchedule> findByDeviceIdAndStatus(String deviceId, ScheduleStatus status);

    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    @Join(value = "device.physicalDevice", type = Join.Type.LEFT_FETCH)
    Optional<DeviceSchedule> findById(UUID uuid);
}
