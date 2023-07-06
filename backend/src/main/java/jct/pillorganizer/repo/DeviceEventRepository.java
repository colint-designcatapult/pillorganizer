package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.model.device.DeviceEvent;

import java.util.Collection;

@Repository
public interface DeviceEventRepository extends JpaRepository<DeviceEvent, Long> {

    @Query("from device_event where device.id = :id order by ts desc")
    Collection<DeviceEvent> findByDeviceID(long id);


}
