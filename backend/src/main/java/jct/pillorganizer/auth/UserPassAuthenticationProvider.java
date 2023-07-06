package jct.pillorganizer.auth;

import io.micronaut.context.annotation.Bean;
import io.micronaut.http.HttpRequest;
import io.micronaut.security.authentication.AuthenticationFailureReason;
import io.micronaut.security.authentication.AuthenticationProvider;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.security.authentication.AuthenticationResponse;
import jakarta.inject.Inject;
import jct.pillorganizer.repo.UserRepository;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * Implements anonymous user authentication using emails and passwords. The username is the user's email. Roles are
 * granted based on the user's role field in their database record and are assigned the "id" attribute for their user
 * ID.
 */
@Bean
public class UserPassAuthenticationProvider implements AuthenticationProvider {

    @Inject
    private UserRepository userRepository;

    @Inject
    private AuthService authService;

    @Override
    public Publisher<AuthenticationResponse> authenticate(HttpRequest<?> httpReq, AuthenticationRequest<?, ?> req) {
        if(!(req instanceof UserPassAuthenticationRequest authReq))
            return Mono.empty();

        try {
            String email = authReq.getIdentity();
            char[] plaintext = authService.toCharArray(authReq.getSecret());

            return userRepository.findByEmail(email)
                    .map((u) -> {
                        if (u == null) {
                            return AuthenticationResponse.failure(AuthenticationFailureReason.USER_NOT_FOUND);
                        } else {
                            if (authService.checkPassword(u, plaintext)) {
                                return AuthenticationResponse.success(
                                        email,
                                        List.of("user", u.getRole().toString()),
                                        Map.of("id", u.getId())
                                );
                            } else {
                                return AuthenticationResponse.failure(
                                        AuthenticationFailureReason.CREDENTIALS_DO_NOT_MATCH);
                            }
                        }
                    })
                    .defaultIfEmpty(AuthenticationResponse.failure(AuthenticationFailureReason.USER_NOT_FOUND));
        } catch (ClassCastException ex) {
            return Mono.just(AuthenticationResponse.failure(AuthenticationFailureReason.UNKNOWN));
        }
    }
}
