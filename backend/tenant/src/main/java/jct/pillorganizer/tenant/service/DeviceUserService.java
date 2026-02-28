package jct.pillorganizer.tenant.service;

import com.github.ksuid.Ksuid;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.dto.DeviceUserDTO;
import jct.pillorganizer.tenant.dto.DeviceUserMapper;
import jct.pillorganizer.tenant.model.device.Device;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import reactor.core.publisher.Flux;

import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Business logic for `DeviceUser` relationships.
 */
@Singleton
public class DeviceUserService {

    @Inject
    DeviceUserRepository repository;
    @Inject
    private KsuidService ksuidService;
    @Inject
    private TenantService tenantService;
    @Inject
    DeviceUserMapper deviceUserMapper;

    public Set<DeviceUserDTO> getDevices(User user) {
        return repository.findDevicesByUserId(user.getId()).stream()
                .map((e) -> deviceUserMapper.toDTO(e))
                .collect(Collectors.toSet());
    }

    public Optional<DeviceUserDTO> getDeviceByClaimToken(User user, String claimToken) {
        return repository.findDevicesByUserId(user.getId()).stream()
                .filter(d -> d.getClaimToken().equals(claimToken))
                .map(e -> deviceUserMapper.toDTO(e))
                .findFirst();
    }

    public Flux<DeviceAccessDto> getDeviceAccess(User user) {
        TenantDetails tenant = tenantService.getCurrentTenant()
                .orElseThrow(() -> new IllegalStateException("No tenant context found"));

        return Flux.fromIterable(repository.findDevicesByUserId(user.getId())
                .stream().map((model) ->
                        new DeviceAccessDto(model.getDeviceId(), model.getNickname(),
                                model.getDeviceClass().toString(),
                                tenant.getId(), tenant.getApiBase(), model.isPrimaryUser()))
                .collect(Collectors.toList()));
    }

    /**
     * Adds a user to a device.
     * @param user user to add to the device
     * @param device  device to add the user to
     * @param primaryUser whether the user should be marked as the primary user of the device
     */
    public void addUserToDevice(User user, Device device, boolean primaryUser) {
        if(!doesUserBelongToDevice(user, device)) {
            DeviceUser du = new DeviceUser();
            du.setId(ksuidService.generateKsuid());
            
            du.setDevice(device);
            du.setUser(user);
            
            du.setPrimaryUser(primaryUser);
            repository.save(du);
        }
    }


    /**
     * Checks if a user is added to a specific device.
     * @param user the user to test membership
     * @param device the device to see whether the user is related to it or not
     * @return true if the user is related to the device
     */
    public boolean doesUserBelongToDevice(User user, Device device) {
        return repository.countByUserIdAndDeviceId(user.getId(), device.getId()) != 0;
    }

    /**
     * Checks if a user has access to a device (is related to the device).
     * @param user the user
     * @param device the device
     * @return true if the user has access to the device
     */
    public boolean userHasAccessToDevice(User user, Device device) {
        return doesUserBelongToDevice(user, device);
    }

}
