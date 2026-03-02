package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record DeviceProvisionMessage(String deviceId, String userId, String serialNo, String claimToken,
                                     String tenantId) implements BaseMessage {
    @Override
    public String getType() {
        return "deviceProvision";
    }
}
