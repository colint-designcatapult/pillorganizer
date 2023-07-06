package jct.pillorganizer.controller.api.app;

import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AnonAuthService;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.UserInfoDTO;
import jct.pillorganizer.dto.UserRegistration;
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
    @Secured({"user", "anon"})
    public Mono<UserInfoDTO> authenticationStatus() {
        long userID = authService.getUserID();
        return userRepo.findUserInfoDTOFromID(userID);
    }

    @Operation(summary = "Upgrades an anonymous account into a standard account",
        description = "Performs an in-place upgrade of an anonymous account into a standard account with an email and " +
                "password. The user ID is preserved.")
    @Post("/anonymous_upgrade")
    @Secured({"anon"})
    public Mono<User> upgradeAnonymous(@Body @Valid UserRegistration registration) {
        long userID = anonAuthService.getUserID();
        byte[] hash = authService.hashPassword(registration.getPassword().toCharArray());
        return userRepo.countByEmail(registration.getEmail())
                .flatMap(number -> {
                    if(number > 0)
                        return Mono.error(Problem.builder().withTitle("A user with that email already exists").build());
                    return Mono.just(number);
                })
                .then(userRepo.upgradeAnonymousUser(userID, registration.getEmail(), hash))
                .flatMap(number -> {
                    if(number == 0)
                        return Mono.error(Problem.builder().withTitle("Already a full user").build());
                    return Mono.empty();
                })
                .then(userRepo.findById(userID));
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
                    if(number > 0)
                        return Mono.error(Problem.builder().withTitle("A user with that email already exists").build());
                    return Mono.just(number);
                })
                .then(userRepo.save(user));
    }

}
