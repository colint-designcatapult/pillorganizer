package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.annotation.Version;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceProvision;
import jct.pillorganizer.proto.Pill;

import javax.annotation.Nullable;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceRepository extends CrudRepository<Device, Long> {

    Optional<Device> findBySerialNo(long serialNo);

    @Query("from device where currentProvision is not null")
    List<Device> findAllProvisioned();

    @Query("select d from device d join d.users u on u.userID = :userID")
    List<Device> findByUserID(long userID);

    List<Device> findAll();

    void update(@Id Long id, @Version Long version, long stateHash, long eventCounter);

    void update(@Id Long id, @Version Long version, DeviceProvision currentProvision);

    void updateLastSyncAndIpv4AndIpv6AndBatteryAndChargingAndEngrData(@Id Long id, @Version Long version, Timestamp lastSync,
                                                                      @Nullable Integer ipv4, @Nullable byte[] ipv6, @Nullable Integer battery, @Nullable Boolean charging, @Nullable String engr_data);

    void update(@Id Long id, String customName);

    void updateBaseTZById(@Id Long id, String baseTZ);

    Optional<Device> findBySerialNoAndCurrentProvisionOobKey(long sn, byte[] oob);

    Optional<Device> findByCurrentProvisionOobKey(byte[] oob);

}
