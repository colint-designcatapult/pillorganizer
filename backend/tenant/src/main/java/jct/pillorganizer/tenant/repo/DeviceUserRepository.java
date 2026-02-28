package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.dto.DeviceUserProjection;
import jct.pillorganizer.tenant.model.device.DeviceUser;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceUserRepository extends CrudRepository<DeviceUser, String> {
    int countByUserIdAndDeviceId(String userId, String deviceId);

    @Join("device")
    Optional<DeviceUser> findByUserIdAndDeviceId(String userId, String deviceId);

    @Join("device")
    Set<DeviceUser> findByUserId(String userId);

    @Query("SELECT d.id as device_id, d.device_class, d.nickname, d.serial_no, d.claim_token, du.primary_user " +
            "FROM device_user du " +
            "JOIN device d ON du.device_id = d.id " +
            "WHERE du.user_id = :userId")
    List<DeviceUserProjection> findDevicesByUserId(String userId);
}
