package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.LogicalDevice;

import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface LogicalDeviceRepository extends CrudRepository<LogicalDevice, String> {
    @Join(value = "physicalDevice", type = Join.Type.LEFT_FETCH)
    @Join(value = "users", type = Join.Type.LEFT_FETCH)
    Optional<LogicalDevice> findById(String id);

    @Join(value = "physicalDevice", type = Join.Type.LEFT_FETCH)
    @Join(value = "currentSchedule", type = Join.Type.LEFT_FETCH)
    @Join(value = "requestedSchedule", type = Join.Type.LEFT_FETCH)
    Optional<LogicalDevice> getById(String id);

    void updateNickname(@Id String logicalDeviceId, String nickname);
    void updateCurrentSchedule(@Id String logicalDeviceId, DeviceSchedule currentSchedule);
    void updateRequestedSchedule(@Id String logicalDeviceId, DeviceSchedule requestedSchedule);
}
