package jct.pillorganizer.core.message;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.core.dto.ShadowStateDto;
import lombok.Builder;

@Builder
@Serdeable
public record IotShadowStateMessage(
        @Nullable Integer timestamp,
        String thingName,
        String clientToken,
        String shadowName,
        String tenant,
        @Nullable ShadowStateDto<?> current,
        @Nullable ShadowStateDto<?> previous
) implements BaseMessage {
    @Override
    public String getType() {
        return "shadow";
    }
}
