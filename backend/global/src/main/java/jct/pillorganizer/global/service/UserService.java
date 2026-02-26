package jct.pillorganizer.global.service;

import com.github.ksuid.Ksuid;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.UserRepo;
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException;

import java.util.Optional;

@Singleton
public class UserService {
    private final UserRepo userRepo;

    @Inject
    public UserService(UserRepo userRepo) {
        this.userRepo = userRepo;
    }

    public UserEntity createUser(String subjectId, String email) {
        // Check if user already exists by subject ID
        Optional<UserEntity> existingUser = userRepo.findBySub(subjectId);
        if (existingUser.isPresent()) {
            return existingUser.get();
        }

        String userId = Ksuid.newKsuid().toString();
        UserEntity newUser = UserEntity.builder()
                .userId(userId)
                .userSub(subjectId)
                .email(email)
                .base(UserEntity.buildBase(userId, subjectId))
                .build();

        try {
            userRepo.save(newUser);
            return newUser;
        } catch (ConditionalCheckFailedException e) {
            // If the save failed due to a condition check failure, it means the user was created concurrently.
            // In this case, we should fetch and return the existing user.
            return userRepo.findBySub(subjectId)
                    .orElseThrow(() -> new IllegalStateException("User creation failed, but user not found for subject ID: " + subjectId));
        }
    }
}
