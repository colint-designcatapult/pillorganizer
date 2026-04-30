package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Requires;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.dto.AdminCognitoUserDto;
import jct.pillorganizer.global.dto.AdminCognitoUserPageDto;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.cognitoidentityprovider.CognitoIdentityProviderClient;
import software.amazon.awssdk.services.cognitoidentityprovider.model.AdminListGroupsForUserRequest;
import software.amazon.awssdk.services.cognitoidentityprovider.model.AttributeType;
import software.amazon.awssdk.services.cognitoidentityprovider.model.ListUsersInGroupRequest;
import software.amazon.awssdk.services.cognitoidentityprovider.model.ListUsersInGroupResponse;
import software.amazon.awssdk.services.cognitoidentityprovider.model.ListUsersRequest;
import software.amazon.awssdk.services.cognitoidentityprovider.model.ListUsersResponse;
import software.amazon.awssdk.services.cognitoidentityprovider.model.UserType;

import java.util.List;

/**
 * Production Cognito implementation of {@link AdminUserService}.
 * Active in the {@code global} (control-plane) environment.
 */
@Singleton
@Flogger
@Requires(env = "global")
public class CognitoAdminUserService implements AdminUserService {

    private final CognitoIdentityProviderClient cognitoClient;
    private final String adminUserPoolId;

    public CognitoAdminUserService(
            CognitoIdentityProviderClient cognitoClient,
            @Value("${app.auth.admin.pool}") String adminUserPoolId) {
        this.cognitoClient = cognitoClient;
        this.adminUserPoolId = adminUserPoolId;
    }

    @Override
    public AdminCognitoUserPageDto listUsers(String paginationToken, int limit) {
        ListUsersRequest.Builder requestBuilder = ListUsersRequest.builder()
                .userPoolId(adminUserPoolId)
                .limit(limit);
        if (paginationToken != null) {
            requestBuilder.paginationToken(paginationToken);
        }

        ListUsersResponse response = cognitoClient.listUsers(requestBuilder.build());

        List<AdminCognitoUserDto> items = response.users().stream()
                .map(u -> toDto(u, fetchGroups(u.username())))
                .toList();

        String nextCursor = response.paginationToken();
        return new AdminCognitoUserPageDto(items, nextCursor != null && !nextCursor.isBlank() ? nextCursor : null);
    }

    @Override
    public AdminCognitoUserPageDto listGroupUsers(String groupName, String paginationToken, int limit) {
        ListUsersInGroupRequest.Builder requestBuilder = ListUsersInGroupRequest.builder()
                .userPoolId(adminUserPoolId)
                .groupName(groupName)
                .limit(limit);
        if (paginationToken != null) {
            requestBuilder.nextToken(paginationToken);
        }

        ListUsersInGroupResponse response = cognitoClient.listUsersInGroup(requestBuilder.build());

        List<AdminCognitoUserDto> items = response.users().stream()
                .map(u -> toDto(u, List.of(groupName)))
                .toList();

        String nextToken = response.nextToken();
        return new AdminCognitoUserPageDto(items, nextToken != null && !nextToken.isBlank() ? nextToken : null);
    }

    private List<String> fetchGroups(String username) {
        return cognitoClient
                .adminListGroupsForUser(AdminListGroupsForUserRequest.builder()
                        .userPoolId(adminUserPoolId)
                        .username(username)
                        .build())
                .groups()
                .stream()
                .map(g -> g.groupName())
                .toList();
    }

    private AdminCognitoUserDto toDto(UserType user, List<String> groups) {
        String sub = user.attributes().stream()
                .filter(a -> "sub".equals(a.name()))
                .map(AttributeType::value)
                .findFirst()
                .orElse(user.username());

        String email = user.attributes().stream()
                .filter(a -> "email".equals(a.name()))
                .map(AttributeType::value)
                .findFirst()
                .orElse(null);

        return new AdminCognitoUserDto(sub, email, user.userStatusAsString(), groups);
    }
}
