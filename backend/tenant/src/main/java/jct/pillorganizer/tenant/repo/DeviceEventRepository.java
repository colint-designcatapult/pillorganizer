package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceEvent;

import java.time.Instant;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceEventRepository extends CrudRepository<DeviceEvent, UUID> {

    @Query("INSERT INTO device_event (id, logical_device_id, timestamp, event_type, bin_id, metadata, schedule_id) " +
           "VALUES (:id, :logicalDeviceId, :timestamp, :eventType, :binId, :metadata, :scheduleId) " +
           "ON CONFLICT ON CONSTRAINT uq_device_event DO NOTHING")
    void saveIdempotent(UUID id, String logicalDeviceId, Instant timestamp, String eventType,
                        @Nullable Integer binId, @Nullable String metadata, @Nullable String scheduleId);
}
