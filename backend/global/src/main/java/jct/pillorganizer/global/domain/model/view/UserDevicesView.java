package jct.pillorganizer.global.domain.model.view;

import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.User;

import java.util.List;

public record UserDevicesView(
        User user,
        List<Device> devices
) {
}
