package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.schedule.DeviceBaseScheduleStrategy;

import java.util.Optional;

@Repository
public interface DeviceScheduleStrategyRepository extends CrudRepository<DeviceBaseScheduleStrategy, Long> {

    @Join("times")
    Optional<DeviceBaseScheduleStrategy> findByDevice(Device device);

}
