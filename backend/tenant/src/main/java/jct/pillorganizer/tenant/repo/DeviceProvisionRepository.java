package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.*;
import io.micronaut.data.jpa.repository.JpaRepository;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.device.DeviceProvision;

import java.util.Optional;

@Repository
public interface DeviceProvisionRepository extends JpaRepository<DeviceProvision, Long> {

    @Join(value = "device", type = Join.Type.FETCH)
    @Query("from device_provision where id = :id and device.serialNo = :sn")
    Optional<DeviceProvision> findByIdAndDevice_SerialNo(long id, long sn);

    @Join(value = "device", type = Join.Type.FETCH)
    @Query("from device_provision and device.serialNo = :sn")
    Optional<DeviceProvision> findBySerialNo(long sn);

    void updateActiveByDeviceAndActive(Device device, boolean active, boolean newActive);

    @Query("from device_provision p where p.device.serialNo = :sn and p.device.currentProvision = p")
    Optional<DeviceProvision> findActiveBySerialNo(long sn);

    void update(@Id Long id, @Version Long version, String bssid, String ssid);


}
