package jct.pillorganizer.tenant.repo;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.LogicalDevice;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceRepository extends CrudRepository<LogicalDevice, String> {

    List<LogicalDevice> findAll();

    @Query("UPDATE logical_device SET nickname = :nickname WHERE id = :id")
    void update(@Id String id, String nickname);

}
