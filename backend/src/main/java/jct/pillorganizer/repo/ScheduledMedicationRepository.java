package jct.pillorganizer.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.annotation.EntityGraph;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.medication.MedicationShape;
import jct.pillorganizer.model.medication.ScheduledMedication;

import java.util.List;
import java.util.Optional;

@Repository
public interface ScheduledMedicationRepository extends CrudRepository<ScheduledMedication, Long> {

    @Join("dispenseTimes")
    ScheduledMedication retrieveById(long id);
    void update(@Id Long id, String med_name, @Nullable MedicationShape shape, @Nullable Integer color);


    @EntityGraph(attributePaths = { "dispenseTimes", "dispenseTimes.dispense"})
    List<ScheduledMedication> retrieveByDevice(Device device);

    @EntityGraph(attributePaths = { "dispenseTimes", "dispenseTimes.dispense"})
    ScheduledMedication retrieveByDeviceAndId(Device device, long id);

    void deleteByIdAndDevice(long id, Device device);

    @Join("dispenseTimes")
    Optional<ScheduledMedication> findByIdAndDevice(long id, Device device);


}
