package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.UserRepository;
import reactor.core.publisher.Mono;

import java.util.Optional;

@Singleton
public class UserService {

    @Inject
    UserRepository repository;

    public User upsert(String userId, String name, String email) {
        return repository.upsert(userId, name, email);
    }

    public User ensureExists(String userId) {
        return repository.saveIdepotent(userId);
    }

    public Optional<User> get(String userId) {
        return repository.findById(userId);
    }

}
