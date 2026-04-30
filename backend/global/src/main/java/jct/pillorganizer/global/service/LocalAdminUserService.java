package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.dto.AdminCognitoUserDto;
import jct.pillorganizer.global.dto.AdminCognitoUserPageDto;
import lombok.extern.flogger.Flogger;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Local / test implementation of {@link AdminUserService}.
 * Returns deterministic fake admin users without touching AWS Cognito.
 * Active in {@code local} and {@code test} environments.
 */
@Singleton
@Flogger
@Requires(env = {"local", "test"})
public class LocalAdminUserService implements AdminUserService {

    private static final List<AdminCognitoUserDto> MOCK_USERS = List.of(
            new AdminCognitoUserDto(
                    "00000000-0000-0000-0000-000000000001",
                    "global-admin@local.dev",
                    "CONFIRMED",
                    List.of("admin-global")
            ),
            new AdminCognitoUserDto(
                    "00000000-0000-0000-0000-000000000002",
                    "tenant-admin-public@local.dev",
                    "CONFIRMED",
                    List.of("admin-tenant-public")
            ),
            new AdminCognitoUserDto(
                    "00000000-0000-0000-0000-000000000003",
                    "invited-user@local.dev",
                    "FORCE_CHANGE_PASSWORD",
                    List.of()
            )
    );

    @Override
    public AdminCognitoUserPageDto listUsers(String paginationToken, int limit) {
        log.atInfo().log("Local: listing all admin pool users (mock), limit=%d", limit);
        List<AdminCognitoUserDto> page = MOCK_USERS.stream().limit(limit).toList();
        return new AdminCognitoUserPageDto(page, null);
    }

    @Override
    public AdminCognitoUserPageDto listGroupUsers(String groupName, String paginationToken, int limit) {
        log.atInfo().log("Local: listing users in group '%s' (mock), limit=%d", groupName, limit);
        List<AdminCognitoUserDto> page = MOCK_USERS.stream()
                .filter(u -> u.groups().contains(groupName))
                .limit(limit)
                .toList();
        return new AdminCognitoUserPageDto(page, null);
    }
}
