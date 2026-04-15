package jct.pillorganizer.tenant.service;

import io.micronaut.data.exceptions.DataAccessException;
import io.micronaut.retry.annotation.Retryable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.tenant.mapper.DeviceMapper;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.projection.UserProfileView;
import jct.pillorganizer.tenant.repo.UserRepository;

import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.function.Function;
import jct.pillorganizer.tenant.repo.DeviceUserRepository;
import jct.pillorganizer.tenant.model.device.DeviceUser;

@Singleton
public class UserService {

    @Inject
    UserRepository repository;
    @Inject
    private DeviceMapper deviceMapper;
    @Inject
    TenantService tenantService;
    @Inject
    DeviceUserRepository deviceUserRepository;

    public User upsert(String userId, String name, String email) {
        return repository.upsert(userId, name, email);
    }

    @Retryable(
            includes = DataAccessException.class,
            attempts = "5",
            delay = "100ms",
            multiplier = "2.0"
    )
    public User ensureExists(String userId) {
        return repository.saveIdempotent(userId);
    }

    public Optional<User> get(String userId) {
        return repository.findById(userId);
    }

    public Optional<UserProfileView> getUserProfile(String userId) {
        return repository.findById(userId).map(user -> new UserProfileView(
                user.getId(),
                user.getUserType().name(),
                user.getName(),
                user.getEmail(),
                user.getDevices()
                        .stream()
                        .map(d -> deviceMapper.toAccessDTO(d, tenantService.getCurrentTenant().get()))
                        .collect(Collectors.toList())));
    }

    public Map<String, DeviceUser> getDeviceUserMap(String userId) {
        return deviceUserRepository.findByUserId(userId).stream()
                .collect(Collectors.toMap(
                        deviceUser -> deviceUser.getDevice().getId(),
                        Function.identity(),
                        (existing, replacement) -> existing));
    }

}
