package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Requires;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.cognitoidentityprovider.CognitoIdentityProviderClient;
import software.amazon.awssdk.services.cognitoidentityprovider.model.AdminDeleteUserRequest;

/**
 * Production implementation of {@link UserAccountService}.
 * Deletes users from the normal Cognito user pool.
 * Active in the {@code global} (control-plane) environment.
 */
@Singleton
@Flogger
@Requires(env = "global")
public class CognitoUserAccountService implements UserAccountService {

    private final CognitoIdentityProviderClient cognitoClient;
    private final String userPoolId;

    public CognitoUserAccountService(
            CognitoIdentityProviderClient cognitoClient,
            @Value("${app.auth.public.pool}") String userPoolId) {
        this.cognitoClient = cognitoClient;
        this.userPoolId = userPoolId;
    }

    @Override
    public void deleteUser(String userSub) {
        log.atInfo().log("Deleting Cognito user with sub %s from pool %s", userSub, userPoolId);
        cognitoClient.adminDeleteUser(AdminDeleteUserRequest.builder()
                .userPoolId(userPoolId)
                .username(userSub)
                .build());
    }
}
