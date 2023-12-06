package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.model.EventType;
import jct.pillorganizer.model.device.DeviceEvent;
import java.util.Optional;
import java.time.Instant;
import java.util.Collection;

@Repository
public interface DeviceEventRepository extends JpaRepository<DeviceEvent, Long> {

    @Query("from device_event where device.id = :id order by ts desc")
    Collection<DeviceEvent> findByDeviceID(long id);

    @Query("from device_event d where d.device.id = :id and d.bin = :binId and d.eventType = :eventType and d.ts >= :time order by d.ts asc")
    Optional<DeviceEvent> findFirstByDeviceIdAndBinIdAndEventTypeClosedAndTsIsAfterOrderByTsAsc(long id, int binId,
            EventType eventType, Instant time);

}
