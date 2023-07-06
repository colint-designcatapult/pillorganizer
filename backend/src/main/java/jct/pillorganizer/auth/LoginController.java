package jct.pillorganizer.auth;

import com.google.protobuf.InvalidProtocolBufferException;
import io.micronaut.context.event.ApplicationEvent;
import io.micronaut.context.event.ApplicationEventPublisher;
import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.problem.HttpStatusType;
import io.micronaut.protobuf.codec.ProtobufferCodec;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.security.authentication.Authenticator;
import io.micronaut.security.event.LoginFailedEvent;
import io.micronaut.security.event.LoginSuccessfulEvent;
import io.micronaut.security.handlers.LoginHandler;
import io.micronaut.security.rules.SecurityRule;
import io.micronaut.security.token.jwt.generator.AccessRefreshTokenGenerator;
import io.micronaut.security.token.jwt.render.AccessRefreshToken;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.proto.Pill;
import lombok.extern.flogger.Flogger;
import org.reactivestreams.Publisher;
import org.zalando.problem.Problem;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import javax.validation.Valid;
import java.util.Optional;

/**
 * Handles logins via HTTP.
 */
@Controller
@Flogger
public class LoginController {

    @Inject
    Authenticator authenticator;
    @Inject
    LoginHandler loginHandler;
    @Inject
    ApplicationEventPublisher<ApplicationEvent> eventPublisher;
    @Inject
    AccessRefreshTokenGenerator accessRefreshTokenGenerator;


    @Operation(summary = "Signs in an anonymous user with their ID/secret credential pair")
    @Consumes(MediaType.APPLICATION_JSON)
    @Post("/api/v1/auth/login_anonymous")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Publisher<MutableHttpResponse<?>> loginAnonymous(@Valid @Body AnonymousAuthenticationRequest creds,
                                                   HttpRequest<?> request) {
        return loginInternal(creds, request);
    }

    @Operation(summary = "Signs in a standard user with their email/password credential pair")
    @Consumes({MediaType.APPLICATION_FORM_URLENCODED, MediaType.APPLICATION_JSON})
        @Post("/api/v1/auth/login")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Publisher<MutableHttpResponse<?>> login(@Valid @Body UserPassAuthenticationRequest creds,
                                                   HttpRequest<?> request) {
        return loginInternal(creds, request);
    }


    @Operation(summary = "Authenticates a device using their credentials in a Protobuf AuthorizeRequest")
    @Post("/api/v1_2/device/auth")
    @Consumes(ProtobufferCodec.PROTOBUFFER_ENCODED)
    @Produces(ProtobufferCodec.PROTOBUFFER_ENCODED)
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Publisher<MutableHttpResponse<?>> login(@Body byte[] body,
                                                   HttpRequest<?> request) {

        try {
            Pill.AuthorizeRequest reqBody = Pill.AuthorizeRequest.parseFrom(body);
            DeviceAuthenticationRequest req = new DeviceAuthenticationRequest(reqBody.getSerialNo(), reqBody);


            return Flux.from(this.authenticator.authenticate(request, req))
                    .map((authenticationResponse) -> {
                        if (authenticationResponse.isAuthenticated() && authenticationResponse.getAuthentication().isPresent()) {
                            Authentication authentication = authenticationResponse.getAuthentication().get();
                            this.eventPublisher.publishEvent(new LoginSuccessfulEvent(authentication));
                            Optional<AccessRefreshToken> art = this.accessRefreshTokenGenerator.generate(authentication);
                            return art.isPresent()
                                    ? buildAccessTokenResponse(art.get())
                                    : HttpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR);
                        } else {
                            this.eventPublisher.publishEvent(new LoginFailedEvent(authenticationResponse));
                            return this.loginHandler.loginFailed(authenticationResponse, request);
                        }
                    });

        } catch (InvalidProtocolBufferException ex) {
            return Flux.just(HttpResponse.status(HttpStatus.UNAUTHORIZED));
        }
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

}
