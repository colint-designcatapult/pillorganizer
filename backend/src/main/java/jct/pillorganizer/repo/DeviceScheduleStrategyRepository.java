package jct.pillorganizer.repo;

import java.util.Optional;

import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.device.schedule.DeviceBaseScheduleStrategy;

@Repository
public interface DeviceScheduleStrategyRepository extends CrudRepository<DeviceBaseScheduleStrategy, Long> {

    @Join("times")
    Optional<DeviceBaseScheduleStrategy> findByDeviceUser(DeviceUser deviceUser);

}
