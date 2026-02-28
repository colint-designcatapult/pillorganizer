package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.device.DeviceClass;
import lombok.Getter;
import lombok.Setter;

@Introspected
@Serdeable
@Getter
@Setter
public class DeviceUserProjection {
    private String deviceId;
    private DeviceClass deviceClass;
    private String nickname;
    private String serialNo;
    private String claimToken;
    private boolean primaryUser;
}
