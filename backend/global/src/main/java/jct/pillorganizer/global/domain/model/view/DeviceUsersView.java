package jct.pillorganizer.global.domain.model.view;

import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.DeviceUserAccess;

import java.util.List;

public record DeviceUsersView(
        Device device,
        List<DeviceUserAccess> users
) {
}
