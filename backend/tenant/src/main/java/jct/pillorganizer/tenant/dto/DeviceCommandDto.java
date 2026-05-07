package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

@Introspected
@Serdeable.Deserializable
@Serdeable.Serializable
public record DeviceCommandDto(
        @NotNull DeviceCommandType type,
        @Nullable DeviceCommandReloadAction reload,
        @Nullable Integer binId,
        @Nullable DeviceCommandBinAction binAction
) {

    public enum DeviceCommandType {
        RELOAD,
        BIN
    }

    public enum DeviceCommandReloadAction {
        INITIATE,
        COMPLETE
    }

    public enum DeviceCommandBinAction {
        TAKEN,
        RESET
    }
}
