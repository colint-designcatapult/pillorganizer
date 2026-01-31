package jct.pillorganizer.auth;

import com.google.protobuf.InvalidProtocolBufferException;
import io.micronaut.context.event.ApplicationEvent;
import io.micronaut.context.event.ApplicationEventPublisher;
import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.problem.HttpStatusType;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.security.authentication.Authenticator;
import io.micronaut.security.event.LoginFailedEvent;
import io.micronaut.security.event.LoginSuccessfulEvent;
import io.micronaut.security.handlers.LoginHandler;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import lombok.extern.flogger.Flogger;
import org.reactivestreams.Publisher;
import org.zalando.problem.Problem;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import jakarta.validation.Valid;
import java.util.Optional;

/**
 * Handles logins via HTTP.
 */
@Controller
@Flogger
public class LoginController {
/*
    @Inject
    Authenticator authenticator;
    @Inject
    LoginHandler loginHandler;
    @Inject
    ApplicationEventPublisher<ApplicationEvent> eventPublisher;
    @Inject
    AccessRefreshTokenGenerator accessRefreshTokenGenerator;

    @Operation(summary = "Signs in a standard user with their email/password credential pair")
    @Consumes({MediaType.APPLICATION_FORM_URLENCODED, MediaType.APPLICATION_JSON})
        @Post("/api/v1/auth/login")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Publisher<MutableHttpResponse<?>> login(@Valid @Body UserPassAuthenticationRequest creds,
                                                   HttpRequest<?> request) {
        return loginInternal(creds, request);
    }

    private MutableHttpResponse<?> buildAccessTokenResponse(AccessRefreshToken art) {

        Pill.AuthorizeResponse.Builder b = Pill.AuthorizeResponse.newBuilder()
                .setAccessToken(art.getAccessToken())
                .setTokenType(art.getTokenType())
                .setExpiresIn(art.getExpiresIn());

        if(art.getRefreshToken() != null)
            b.setRefreshToken(b.getRefreshToken());


        return HttpResponse.ok(
                b.build().toByteArray()
        );
    }

    private Publisher<MutableHttpResponse<?>> loginInternal(AuthenticationRequest<?, ?> creds,
                                                            HttpRequest<?> request) {
        return Flux.from(this.authenticator.authenticate(request, creds)).map((authenticationResponse) -> {
                    if (authenticationResponse.isAuthenticated() && authenticationResponse.getAuthentication().isPresent()) {
                        Authentication authentication = authenticationResponse.getAuthentication().get();
                        this.eventPublisher.publishEvent(new LoginSuccessfulEvent(authentication));
                        return this.loginHandler.loginSuccess(authentication, request);
                    } else {
                        this.eventPublisher.publishEvent(new LoginFailedEvent(authenticationResponse));
                        return this.loginHandler.loginFailed(authenticationResponse, request);
                    }
                })
                .switchIfEmpty(Mono.error(new AuthenticationException("No authentication provider")))
                .onErrorResume(AuthenticationException.class, thr -> Mono.error(
                        Problem.builder()
                                .withStatus(new HttpStatusType(HttpStatus.UNAUTHORIZED))
                                .withTitle(thr.getMessage())
                                .build()
                ));
    }
*/
}
