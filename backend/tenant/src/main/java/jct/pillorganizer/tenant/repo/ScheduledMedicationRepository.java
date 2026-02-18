package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Join;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.jpa.annotation.EntityGraph;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.medication.MedicationShape;
import jct.pillorganizer.tenant.model.medication.ScheduledMedication;

import java.util.List;
import java.util.Optional;

@Repository
public interface ScheduledMedicationRepository extends CrudRepository<ScheduledMedication, Long> {

    @Join("dispenseTimes")
    ScheduledMedication retrieveById(long id);
    void update(@Id Long id, String med_name, @Nullable MedicationShape shape, @Nullable Integer color);


    @EntityGraph(attributePaths = { "dispenseTimes", "dispenseTimes.dispense"})
    List<ScheduledMedication> retrieveByDeviceUser(DeviceUser deviceUser);

    @EntityGraph(attributePaths = { "dispenseTimes", "dispenseTimes.dispense"})
    ScheduledMedication retrieveByDeviceUserAndId(DeviceUser deviceUser, long id);

    @Join("dispenseTimes")
    Optional<ScheduledMedication> findByIdAndDeviceUser(long id, DeviceUser deviceUser);


}
