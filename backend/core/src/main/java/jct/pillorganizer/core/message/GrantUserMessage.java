package jct.pillorganizer.core.message;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record GrantUserMessage(String userId, String userName, String email) implements BaseMessage {
    @Override
    public String getType() {
        return "grantUser";
    }
}
