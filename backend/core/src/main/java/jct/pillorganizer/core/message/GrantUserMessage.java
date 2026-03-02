package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record GrantUserMessage(String userId, String userName, String email, String tenantId) implements BaseMessage {
    @Override
    public String getType() {
        return "grantUser";
    }
}
