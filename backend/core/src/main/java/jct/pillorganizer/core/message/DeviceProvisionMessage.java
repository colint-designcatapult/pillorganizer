package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record DeviceProvisionMessage(String deviceId, String userId, String serialNo, String claimId,
                                     String tenantId, String thingName) implements BaseMessage {
    @Override
    public String getType() {
        return "deviceProvision";
    }
}
