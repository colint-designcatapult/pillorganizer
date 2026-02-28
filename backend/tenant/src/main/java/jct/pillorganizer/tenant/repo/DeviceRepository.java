package jct.pillorganizer.tenant.repo;

import java.util.List;
import java.util.Optional;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.Device;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceRepository extends CrudRepository<Device, String> {

    Optional<Device> findBySerialNo(String serialNo);

    List<Device> findAll();

    @Query("UPDATE device SET nickname = :nickname WHERE id = :id")
    void update(@Id String id, String nickname);

}
