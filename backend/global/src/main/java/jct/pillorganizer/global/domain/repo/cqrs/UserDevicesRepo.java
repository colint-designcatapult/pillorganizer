package jct.pillorganizer.global.domain.repo.cqrs;

import jct.pillorganizer.global.domain.model.view.UserDevicesView;

import java.util.Optional;

public interface UserDevicesRepo {
    Optional<UserDevicesView> get(String userId);
}
