package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceUser;
import reactor.core.publisher.Mono;

@Repository
public interface DeviceUserAsyncRepository extends ReactorCrudRepository<DeviceUser, Long> {
    Mono<Device> retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(long userID, long deviceID);
}
