package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record DeleteUserMessage(String userId) implements BaseMessage {
    @Override
    public String getType() {
        return "deleteUser";
    }
}
