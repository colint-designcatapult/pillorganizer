package jct.pillorganizer.controller.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.MutableHttpResponse;
import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AnonAuthService;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.*;
import jct.pillorganizer.model.user.AnonymousUser;
import jct.pillorganizer.model.user.User;
import jct.pillorganizer.model.user.UserRole;
import jct.pillorganizer.repo.AnonymousUserRepository;
import jct.pillorganizer.repo.UserRepository;
import org.zalando.problem.Problem;
import reactor.core.publisher.Mono;

import javax.validation.Valid;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

@Controller("/api/v1/user")
public class AppUserController {

    @Inject
    AnonymousUserRepository anonRepo;

    @Inject
    UserRepository userRepo;

    @Inject
    AnonAuthService anonAuthService;

    @Inject
    AuthService authService;

    @Operation(summary = "Creates an anonymous user")
    @Post("/register_anonymous")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Mono<AnonymousUser> anonymousRegistration() throws NoSuchAlgorithmException {
        SecureRandom sr = SecureRandom.getInstanceStrong();
        AnonymousUser nu = new AnonymousUser();
        nu.setSecret(sr.generateSeed(12));
        nu.setRole(UserRole.USER);
        return anonRepo.save(nu);
    }

    @Operation(summary = "Gets info about currently signed-in user")
    @Get("/me")
    @Secured({ "user", "anon" })
    public Mono<UserInfoDTO> authenticationStatus() {
        long userID = authService.getUserID();
        return userRepo.findUserInfoDTOFromID(userID);
    }

    @Operation(summary = "Register a standard account.")
    @Post("/register")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Mono<User> register(@Body @Valid UserRegistration registration) {
        User user = new User();
        user.setEmail(registration.getEmail());
        user.setPasswordHash(authService.hashPassword(registration.getPassword().toCharArray()));
        user.setRole(UserRole.USER);
        return userRepo.countByEmail(registration.getEmail())
                .flatMap(number -> {
                    if (number > 0)
                        return Mono.error(Problem.builder().withTitle("A user with that email already exists").build());
                    return Mono.just(number);
                })
                .then(userRepo.save(user));
    }

    @Operation(summary = "Change email of a logged in account")
    @Put("/change_email")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> changeEmail(@Body @Valid ChangeEmailDTO emailChange) throws IllegalAccessException {
        authService.changeEmail(emailChange.getCurrentEmail(), emailChange.getNewEmail());
        return HttpResponse.ok();
    }

    @Operation(summary = "Change password of a logged in account")
    @Put("/change_password")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> changePassword(@Body @Valid ChangePasswordDTO passwordChange) throws IllegalAccessException {
        authService.changePassword(passwordChange.getCurrentPassword(), passwordChange.getNewPassword());
        return HttpResponse.ok();
    }

    @Operation(summary = "reset password of a user that went through the email process")
    @Put("/new_password")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Mono<MutableHttpResponse<Object>> newPassword(@Body @Valid NewPasswordDTO passwordChange)
            throws IllegalAccessException {
        return userRepo.getRecoveryCodeByEmail(passwordChange.getEmail())
                .flatMap(number -> {
                    boolean validationSuccessful = (number == passwordChange.getRecoveryCode());
                    if (validationSuccessful) {
                        try {
                            userRepo.updateUserRecoveryCode(null, passwordChange.getEmail());
                            authService.newPassword(passwordChange.getEmail(),
                                    passwordChange.getNewPassword());
                            return Mono.just(HttpResponse.accepted());
                        } catch (IllegalAccessException e) {
                            e.printStackTrace();
                            return Mono.error(new IllegalAccessException("Internal server error."));
                        }
                    }
                    return Mono.just(HttpResponse.status(HttpStatus.UNAUTHORIZED));
                })
                .defaultIfEmpty(HttpResponse.notFound());
    }

}
