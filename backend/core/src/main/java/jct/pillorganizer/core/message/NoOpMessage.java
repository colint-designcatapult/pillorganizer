package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record NoOpMessage() implements BaseMessage {
    @Override
    public String getType() {
        return "noop";
    }
}
