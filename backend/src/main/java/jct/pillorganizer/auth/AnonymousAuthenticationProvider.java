package jct.pillorganizer.auth;

import io.micronaut.data.exceptions.EmptyResultException;
import io.micronaut.http.HttpRequest;
import io.micronaut.security.authentication.AuthenticationFailureReason;
import io.micronaut.security.authentication.AuthenticationProvider;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.security.authentication.AuthenticationResponse;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.repo.AnonymousUserRepository;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;

/**
 * Implements anonymous user authentication using IDs and secrets. Anonymous users have a username in the format
 * "$anon$(USER ID)", have the "anon" role, and their ID is added to the "id" attribute. Note that anonymous users
 * are not granted any other role.
 * @see jct.pillorganizer.model.user.AnonymousUser
 */
@Singleton
public class AnonymousAuthenticationProvider implements AuthenticationProvider {

    @Inject
    AnonymousUserRepository anonRepo;

    @Override
    public Publisher<AuthenticationResponse> authenticate(HttpRequest<?> http, AuthenticationRequest<?, ?> req) {
        if(!(req instanceof AnonymousAuthenticationRequest anonReq))
            return Mono.empty();

        try {

            long id = anonReq.getIdentity();
            byte[] secret = HexFormat.of().parseHex(anonReq.getSecret());

            return anonRepo.findById(id)
                    .onErrorResume(EmptyResultException.class, thr -> Mono.empty())
                    .map(anon -> {
                        if (Arrays.equals(anon.getSecret(), secret)) {
                            return AuthenticationResponse.success(
                                    "$anon#" + id,
                                    List.of("anon"),
                                    Map.of("id", id)
                            );
                        } else {
                            return AuthenticationResponse.failure(AuthenticationFailureReason.CREDENTIALS_DO_NOT_MATCH);
                        }
                    })
                    .switchIfEmpty(Mono.just(AuthenticationResponse.failure(AuthenticationFailureReason.USER_NOT_FOUND)));
        } catch (ClassCastException | IllegalArgumentException ex) {
            return Mono.just(AuthenticationResponse.failure(AuthenticationFailureReason.UNKNOWN));
        }
    }
}
