package jct.pillorganizer.global.service;

import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.token.validator.TokenValidator;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.uid.KsuidService;
import jct.pillorganizer.global.exception.UserEntityNotFoundException;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.UserRepo;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException;

import java.util.Optional;

@Singleton
@Flogger
public class UserService {
    private final KsuidService ksuidService;
    private final UserRepo userRepo;
    private final TokenValidator<?> tokenValidator;
    private final NotificationEndpointService notificationEndpointService;

    @Inject
    public UserService(UserRepo userRepo, KsuidService ksuidService, TokenValidator<?> tokenValidator,
                       NotificationEndpointService notificationEndpointService) {
        this.userRepo = userRepo;
        this.ksuidService = ksuidService;
        this.tokenValidator = tokenValidator;
        this.notificationEndpointService = notificationEndpointService;
    }

    public UserEntity createUser(String sub, String email) {
        // Check if user already exists by subject ID
        Optional<UserEntity> existingUser = userRepo.findBySub(sub);
        if (existingUser.isPresent()) {
            return existingUser.get();
        }

        String userId = ksuidService.generateKsuid();
        UserEntity newUser = UserEntity.builder()
                .userId(userId)
                .userSub(sub)
                .email(email)
                .base(UserEntity.buildBase(userId, sub))
                .build();

        try {
            userRepo.save(newUser);
            return newUser;
        } catch (ConditionalCheckFailedException e) {
            // If the save failed due to a condition check failure, it means the user was created concurrently.
            // In this case, we should fetch and return the existing user.
            return userRepo.findBySub(sub)
                    .orElseThrow(() -> new IllegalStateException("User creation failed, but user not found for " +
                            "sub: " + sub, e));
        }
    }

    public UserEntity getOrCreateUser(String sub, String email) {
        Optional<UserEntity> existingUser = userRepo.findBySub(sub);
        if (existingUser.isPresent()) {
            return existingUser.get();
        }

        log.atWarning().log("User with sub %s does not exist, creating one", sub);
        return createUser(sub, email);
    }

    public Optional<UserEntity> get(String userId) {
        return userRepo.findAllByUserId(userId).stream().findFirst();
    }

    public Optional<UserEntity> findByEmail(String email) {
        return userRepo.findByEmail(email);
    }

    public Optional<UserEntity> getBySubject(String sub) {
        return userRepo.findBySub(sub).stream().findFirst();
    }

    public Mono<UserEntity> authenticateJwt(String jwtToken) {
        return Mono.from(this.tokenValidator.validateToken(jwtToken, null))
                .switchIfEmpty(Mono.defer(() -> {
                    log.atWarning().log("JWT token validation failed");
                    return Mono.error(new AuthenticationException("Invalid JWT token"));
                }))
                .map((auth) -> {
                    String sub = (String) auth.getAttributes().get("sub");
                    return getBySubject(sub).orElseThrow(() -> {
                        log.atWarning().log("Verified JWT token for subject `%s` but no user entity found", sub);
                        return new UserEntityNotFoundException("Subject " + sub);
                    });
                });
    }

    /**
     * Registers or refreshes the user's FCM token as an SNS platform-application endpoint,
     * then persists the resulting endpoint ARN on the {@link UserEntity}.
     *
     * @param user     the user whose token is being registered
     * @param fcmToken the current FCM registration token from the device
     * @return the updated {@link UserEntity} containing the new {@code fcmEndpointArn}
     */
    public UserEntity registerFcmToken(UserEntity user, String fcmToken) {
        String endpointArn = notificationEndpointService.registerOrUpdateEndpoint(
                fcmToken, user.getFcmEndpointArn());

        if (endpointArn.equals(user.getFcmEndpointArn())) {
            return user;
        }

        userRepo.updateFcmEndpointArn(user, endpointArn);
        log.atInfo().log("Persisted FCM endpoint ARN for user %s", user.getUserId());
        return user.toBuilder().fcmEndpointArn(endpointArn).build();
    }
}
