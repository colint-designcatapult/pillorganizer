package jct.pillorganizer.global.domain.repo.cqrs;

import jct.pillorganizer.global.domain.model.view.DeviceUsersView;

import java.util.Optional;

public interface DeviceUsersRepo {
    Optional<DeviceUsersView> get(String deviceId);
}
