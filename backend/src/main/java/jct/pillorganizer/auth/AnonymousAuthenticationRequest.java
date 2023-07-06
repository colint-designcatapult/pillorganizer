package jct.pillorganizer.auth;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;

/**
 * DTO for serializing anonymous authentication requests via JSON.
 */
@AllArgsConstructor
@Serdeable.Deserializable
@Serdeable.Serializable
public class AnonymousAuthenticationRequest implements AuthenticationRequest<Long, String> {

    @JsonProperty("id")
    private final long id;
    @JsonProperty("secret")
    private final String secret;

    @Override
    @JsonProperty("id")
    public Long getIdentity() {
        return id;
    }

    @Override
    public String getSecret() {
        return secret;
    }

}
