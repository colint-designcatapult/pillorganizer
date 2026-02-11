package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import reactor.core.publisher.Mono;

@Repository
public interface DeviceUserAsyncRepository extends ReactorCrudRepository<DeviceUser, Long> {
    Mono<Device> retrieveDeviceByUserIDAndDeviceIDAndDeletedFalse(long userID, long deviceID);
}
