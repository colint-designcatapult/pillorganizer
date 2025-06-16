package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.DeviceCaregiverCode;

import java.sql.Timestamp;
import java.util.Optional;

@Repository
public interface CaregiverRepository extends CrudRepository<DeviceCaregiverCode, Long> {
    /**
     * Find a valid caregiver code by the code value
     * where the code is not expired and not deleted.
     *
     * @param code The 8-digit code
     * @param currentTimestamp The current timestamp for expiration check
     * @return The caregiver code if found and valid
     */
    Optional<DeviceCaregiverCode> findByCodeAndExpiresAtGreaterThanAndDeletedFalse(
            long code,
            Timestamp currentTimestamp
    );
}