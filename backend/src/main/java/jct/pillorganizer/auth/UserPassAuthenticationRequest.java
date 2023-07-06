package jct.pillorganizer.auth;

import io.micronaut.security.authentication.UsernamePasswordCredentials;
import io.micronaut.serde.annotation.Serdeable;

/**
 * Standard user authentication request to differentiate from the other authentiation types.
 */
@Serdeable.Deserializable
public class UserPassAuthenticationRequest extends UsernamePasswordCredentials {
}
