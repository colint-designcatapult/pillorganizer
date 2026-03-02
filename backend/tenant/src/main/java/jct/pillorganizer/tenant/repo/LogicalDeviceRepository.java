package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Join;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.LogicalDevice;

import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface LogicalDeviceRepository extends CrudRepository<LogicalDevice, UUID> {
    @Join("physicalDevice")
    Optional<LogicalDevice> findById(UUID id);
}
