package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.CaregiverCode;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface CaregiverCodeRepository extends CrudRepository<CaregiverCode, UUID> {

    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    Optional<CaregiverCode> findByCodeAndDeletedFalseAndExpiresAtGreaterThan(int code, java.sql.Timestamp now);

    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    List<CaregiverCode> findByDeviceIdAndDeletedFalseAndExpiresAtGreaterThan(String deviceId, java.sql.Timestamp now);

    @Query("UPDATE caregiver_code SET deleted = TRUE WHERE device_id = :deviceId AND deleted = FALSE")
    void invalidateAllForDevice(String deviceId);

    @Query("UPDATE caregiver_code SET deleted = TRUE WHERE id = :id")
    void markDeleted(@Id UUID id);
}
