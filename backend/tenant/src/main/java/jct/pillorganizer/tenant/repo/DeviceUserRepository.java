package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.model.user.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceUserRepository extends CrudRepository<DeviceUser, UUID> {
    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    @Join(value = "device.physicalDevice", type = Join.Type.LEFT_FETCH)
    Optional<DeviceUser> findByUserAndDevice(User userId, LogicalDevice deviceId);

    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    @Join(value = "device.physicalDevice", type = Join.Type.LEFT_FETCH)
    @Join(value = "user", type = Join.Type.LEFT_FETCH)
    List<DeviceUser> findByUserId(String userId);

    @Join(value = "device", type = Join.Type.LEFT_FETCH)
    @Join(value = "device.physicalDevice", type = Join.Type.LEFT_FETCH)
    @Join(value = "user", type = Join.Type.LEFT_FETCH)
    Optional<DeviceUser> findByUserAndDeviceId(User user, String deviceId);

    @Join(value = "user", type = Join.Type.LEFT_FETCH)
    List<DeviceUser> findByDeviceId(String deviceId);

    void updateSubscriptionArn(@Id UUID id, @Nullable String subscriptionArn);

    void updateNickname(@Id UUID id, @Nullable String nickname);
}
