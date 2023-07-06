package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.annotation.EntityGraph;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.medication.ScheduledMedication;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository
public interface ScheduledMedicationAsyncRepository extends ReactorCrudRepository<ScheduledMedication, Long> {

    Flux<ScheduledMedication> findByDevice(Device device);

    @EntityGraph(attributePaths = {"doses", "dispenseTimes"})
    Flux<ScheduledMedication> retrieveByDevice(Device device);

    @EntityGraph(attributePaths = {"doses", "dispenseTimes"})
    Mono<ScheduledMedication> retrieveByDeviceAndId(Device device, long id);


    Mono<Long> deleteByIdAndDevice(long id, Device device);
}
