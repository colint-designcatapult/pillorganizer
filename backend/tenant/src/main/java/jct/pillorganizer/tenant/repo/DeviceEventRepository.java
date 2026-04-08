package jct.pillorganizer.tenant.repo;

import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceEvent;

import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceEventRepository extends CrudRepository<DeviceEvent, UUID> {
}
