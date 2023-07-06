package jct.pillorganizer.auth;

import io.micronaut.security.authentication.AuthenticationRequest;
import jct.pillorganizer.proto.Pill;
import lombok.AllArgsConstructor;

/**
 * Wraps a protobuf AuthorizeRequest for use in the Micronaut Security framework.
 */
@AllArgsConstructor
public class DeviceAuthenticationRequest implements AuthenticationRequest<Long, Pill.AuthorizeRequest> {

    private final long serialNo;
    private final Pill.AuthorizeRequest req;

    @Override
    public Long getIdentity() {
        return serialNo;
    }

    @Override
    public Pill.AuthorizeRequest getSecret() {
        return req;
    }
}
