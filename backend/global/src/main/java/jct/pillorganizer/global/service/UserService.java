package jct.pillorganizer.global.service;

import com.github.ksuid.Ksuid;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.service.GlobalAuthService;
import jct.pillorganizer.core.uid.KsuidService;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.UserRepo;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException;

import java.util.Optional;

@Singleton
@Flogger
public class UserService {
    private final KsuidService ksuidService;
    private final UserRepo userRepo;

    @Inject
    public UserService(UserRepo userRepo, KsuidService ksuidService) {
        this.userRepo = userRepo;
        this.ksuidService = ksuidService;
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
}
