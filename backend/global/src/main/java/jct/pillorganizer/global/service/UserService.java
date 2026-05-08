package jct.pillorganizer.global.service;

import io.micronaut.security.authentication.AuthenticationException;
import io.micronaut.security.token.validator.TokenValidator;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.uid.KsuidService;
import jct.pillorganizer.core.message.DeleteUserMessage;
import jct.pillorganizer.global.exception.UserEntityNotFoundException;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.UserRepo;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException;

import java.io.IOException;
import java.util.Optional;

@Singleton
@Flogger
public class UserService {
    private final KsuidService ksuidService;
    private final UserRepo userRepo;
    private final TokenValidator<?> tokenValidator;
    private final NotificationEndpointService notificationEndpointService;
    private final UserAccountService userAccountService;
    private final TenantMessageService tenantMessageService;

    @Inject
    public UserService(UserRepo userRepo, KsuidService ksuidService, TokenValidator<?> tokenValidator,
                       NotificationEndpointService notificationEndpointService,
                       UserAccountService userAccountService,
                       TenantMessageService tenantMessageService) {
        this.userRepo = userRepo;
        this.ksuidService = ksuidService;
        this.tokenValidator = tokenValidator;
        this.notificationEndpointService = notificationEndpointService;
        this.userAccountService = userAccountService;
        this.tenantMessageService = tenantMessageService;
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

    /**
     * Permanently deletes a user account:
     * 1. Deletes the Cognito user from the normal user pool
     * 2. Deletes the UserEntity from the control plane
     * 3. Broadcasts a deleteUser message to every tenant's queue
     */
    public void deleteAccount(UserEntity user) throws IOException {
        log.atInfo().log("Deleting account for user %s (sub: %s)", user.getUserId(), user.getUserSub());

        // Delete from Cognito
        userAccountService.deleteUser(user.getUserSub());

        // Delete from control plane
        userRepo.delete(user);

        // Broadcast to all tenants
        DeleteUserMessage message = DeleteUserMessage.builder()
                .userId(user.getUserId())
                .build();
        tenantMessageService.broadcastDeleteUser(message);

        log.atInfo().log("Account deletion completed for user %s", user.getUserId());
    }
}
