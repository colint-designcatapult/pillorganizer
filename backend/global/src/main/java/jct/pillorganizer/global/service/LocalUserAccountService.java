package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;

/**
 * Local / test implementation of {@link UserAccountService}.
 * Prints delete operations to console without touching AWS Cognito.
 * Active in {@code local} and {@code test} environments.
 */
@Singleton
@Flogger
@Requires(env = {"local", "test"})
@Replaces(CognitoUserAccountService.class)
public class LocalUserAccountService implements UserAccountService {

    @Override
    public void deleteUser(String userSub) {
        log.atInfo().log("Local: would delete Cognito user with sub %s", userSub);
    }
}
