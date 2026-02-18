package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.schedule.DeviceSimpleDispenseTime;

import java.time.LocalTime;

@Repository
public interface DeviceSimpleDispenseTimeRepository extends CrudRepository<DeviceSimpleDispenseTime, Long> {

    void update(@Id Long id, LocalTime time);

}
