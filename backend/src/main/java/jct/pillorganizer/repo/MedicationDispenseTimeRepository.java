package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.medication.MedicationDispenseTime;

import java.util.List;
import java.util.Optional;

@Repository
public interface MedicationDispenseTimeRepository extends CrudRepository<MedicationDispenseTime, Long> {

    Optional<MedicationDispenseTime> findByDispenseIDAndMedicationID(long dispenseID, long medicationID);

    List<MedicationDispenseTime> findByMedicationID(long medicationID);

    void deleteById(long id);

}
