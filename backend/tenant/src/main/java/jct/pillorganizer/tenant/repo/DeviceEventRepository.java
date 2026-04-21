package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.projection.DoseHistoryView;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface DeviceEventRepository extends CrudRepository<DeviceEvent, UUID> {

    @Query("INSERT INTO device_event (id, logical_device_id, timestamp, event_type, bin_id, metadata, schedule_id, " +
            "epoch_week, scheduled_time) " +
           "VALUES (:id, :logicalDeviceId, :timestamp, :eventType, :binId, :metadata, :scheduleId, :epochWeek, :scheduledTime) " +
           "ON CONFLICT ON CONSTRAINT uq_device_event DO NOTHING")
    void saveIdempotent(UUID id, String logicalDeviceId, Instant timestamp, String eventType,
                        @Nullable Integer binId, @Nullable String metadata, @Nullable String scheduleId,
                        @Nullable Instant epochWeek, @Nullable Instant scheduledTime);

    @Query("""
            WITH ResolvedDoses AS (
            SELECT DISTINCT ON (logical_device_id, epoch_week, bin_id)
                logical_device_id,
                epoch_week,
                bin_id,
                scheduled_time,
                event_type AS final_status,
                timestamp AS resolved_time,
                schedule_id
            FROM device_event
            WHERE logical_device_id = :deviceId\s
              AND scheduled_time <= :cursorTime
              AND scheduled_time >= CAST(:cursorTime AS TIMESTAMPTZ) - INTERVAL '14 days'
              AND event_type IN ('TAKEN', 'MISSED', 'TAKE_NOW')
            ORDER BY logical_device_id, epoch_week, bin_id, timestamp DESC
        )
        SELECT\s
            r.logical_device_id,
            r.epoch_week,
            r.bin_id,
            r.scheduled_time,
            r.final_status,
            r.resolved_time,
            s.timezone_iana AS device_time_zone 
        FROM ResolvedDoses r
        JOIN device_schedule s ON s.id::text = r.schedule_id
        ORDER BY r.scheduled_time DESC
        LIMIT :limit
    """)
    List<DoseHistoryView> getResolvedHistory(String deviceId, Instant cursorTime, int limit);
}
