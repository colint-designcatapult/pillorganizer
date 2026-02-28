package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record DeviceProvisionMessage(String claimToken, String deviceId, String userId, String serialNo) implements BaseMessage {
    @Override
    public String getType() {
        return "deviceProvision";
    }
}
