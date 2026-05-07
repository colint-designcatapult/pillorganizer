package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceEvent;
import jct.pillorganizer.tenant.projection.DeviceUserAdherenceSummaryView;
import jct.pillorganizer.tenant.projection.DoseHistoryView;
import jct.pillorganizer.tenant.projection.WeeklyEventView;

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
              AND scheduled_time >= make_timestamptz(:year, :month, 1, 0, 0, 0, :timezone)
              AND scheduled_time < make_timestamptz(:year, :month, 1, 0, 0, 0, :timezone) + INTERVAL '1 month'
              AND event_type IN ('TAKEN', 'MISSED', 'TAKE_NOW', 'BIN_RESET')
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
    """)
    List<DoseHistoryView> getResolvedMonthAdherenceHistory(String deviceId, int year, int month, String timezone);

    @Query("""
        WITH LatestEvent AS (
            SELECT logical_device_id, MAX(timestamp) AS latest_ts
            FROM device_event
            GROUP BY logical_device_id
        ),
        DeviceUsers AS (
            SELECT DISTINCT ON (pr.serial_no, du.user_id)
                ld.id AS device_id,
                pr.serial_no,
                du.user_id
            FROM logical_device ld
            JOIN provision_record pr ON pr.claim_id = ld.physical_device_id
            JOIN device_user du ON du.device_id = ld.id
            JOIN LatestEvent le ON le.logical_device_id = ld.id
            WHERE ld.disabled_at IS NULL
            ORDER BY pr.serial_no, du.user_id, le.latest_ts DESC
        ),
        ResolvedDoses AS (
            SELECT DISTINCT ON (logical_device_id, epoch_week, bin_id)
                logical_device_id,
                event_type AS final_status
            FROM device_event
            WHERE scheduled_time >= make_timestamptz(:year, :month, 1, 0, 0, 0, 'UTC')
              AND scheduled_time < make_timestamptz(:year, :month, 1, 0, 0, 0, 'UTC') + INTERVAL '1 month'
              AND event_type IN ('TAKEN', 'MISSED', 'TAKE_NOW', 'BIN_RESET')
            ORDER BY logical_device_id, epoch_week, bin_id, timestamp DESC
        ),
        Aggregated AS (
            SELECT
                logical_device_id,
                COUNT(*) AS doses_scheduled,
                COUNT(CASE WHEN final_status IN ('TAKEN', 'TAKE_NOW') THEN 1 END) AS doses_taken
            FROM ResolvedDoses
            GROUP BY logical_device_id
        )
        SELECT
            du.serial_no AS serial_number,
            du.user_id,
            du.device_id,
            COALESCE(a.doses_taken, 0) AS doses_taken,
            COALESCE(a.doses_scheduled, 0) AS doses_scheduled
        FROM DeviceUsers du
        JOIN Aggregated a ON a.logical_device_id = du.device_id
        WHERE (CAST(:snFilter AS TEXT) IS NULL OR du.serial_no ILIKE '%' || :snFilter || '%')
          AND (CAST(:cursorSn AS TEXT) IS NULL OR (du.serial_no, du.user_id) > (:cursorSn, :cursorUid))
        ORDER BY du.serial_no, du.user_id
        LIMIT :size
    """)
    List<DeviceUserAdherenceSummaryView> getDeviceUserAdherenceSummaries(
            int year,
            int month,
            @io.micronaut.core.annotation.Nullable String snFilter,
            @io.micronaut.core.annotation.Nullable String cursorSn,
            @io.micronaut.core.annotation.Nullable String cursorUid,
            int size);

    @Query("""
        SELECT DISTINCT ON (epoch_week, bin_id)
            bin_id,
            scheduled_time,
            event_type AS final_status,
            timestamp AS resolved_time
        FROM device_event
        WHERE logical_device_id = :deviceId
          AND scheduled_time >= :weekStart
          AND scheduled_time < :weekEnd
          AND event_type IN ('TAKEN', 'MISSED', 'TAKE_NOW', 'BIN_RESET')
        ORDER BY epoch_week, bin_id, timestamp DESC
    """)
    List<WeeklyEventView> getWeeklyEvents(String deviceId, Instant weekStart, Instant weekEnd);
}
