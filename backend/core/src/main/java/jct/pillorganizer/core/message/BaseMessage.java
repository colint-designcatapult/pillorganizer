package jct.pillorganizer.core.message;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import io.micronaut.serde.annotation.Serdeable;

@JsonTypeInfo(
        use = JsonTypeInfo.Id.NAME,
        include = JsonTypeInfo.As.PROPERTY,
        property = "type"
)
@JsonSubTypes({
        @JsonSubTypes.Type(value = NoOpMessage.class, name = "noop"),
        @JsonSubTypes.Type(value = GrantUserMessage.class, name = "grantUser"),
        @JsonSubTypes.Type(value = DeviceProvisionMessage.class, name = "deviceProvision"),
        @JsonSubTypes.Type(value = IotShadowStateMessage.class, name = "shadow"),
        @JsonSubTypes.Type(value = IotDeviceEventMessage.class, name = "deviceEvent"),
        @JsonSubTypes.Type(value = DeleteUserMessage.class, name = "deleteUser")
})
@Serdeable
public interface BaseMessage {
    String getType();
}
