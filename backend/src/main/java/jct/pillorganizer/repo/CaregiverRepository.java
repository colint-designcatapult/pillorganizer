package jct.pillorganizer.repo;

import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.DeviceCaregiverCode;

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

    /**
     * Find all valid caregiver codes for specific devices
     * where the codes are not expired and not deleted.
     *
     * @param deviceIds List of device IDs to filter by
     * @param currentTimestamp The current timestamp for expiration check
     * @return List of valid caregiver codes for the specified devices
     */
    List<DeviceCaregiverCode> findByDeviceIDInAndExpiresAtGreaterThanAndDeletedFalse(
            Set<Long> deviceIds,
            Timestamp currentTimestamp
    );

    /**
     * Find all caregiver codes for a specific device that are not deleted.
     *
     * @param deviceId The device ID to filter by
     * @return List of all caregiver codes for the specified device
     */
    List<DeviceCaregiverCode> findByDeviceIDAndDeletedFalse(long deviceId);
}