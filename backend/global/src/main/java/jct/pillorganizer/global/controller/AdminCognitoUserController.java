package jct.pillorganizer.global.controller;

import io.micronaut.core.annotation.Blocking;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.global.dto.AdminCognitoUserPageDto;
import jct.pillorganizer.global.service.AdminUserService;

@Controller
@Secured(AppSecurityRule.IS_GLOBAL_ADMIN)
@Blocking
public class AdminCognitoUserController {

    @Inject
    AdminUserService adminUserService;

    @Get("/admin/cognito-users")
    public AdminCognitoUserPageDto listUsers(
            @Nullable @QueryValue String cursor,
            @QueryValue(defaultValue = "20") int size) {
        return adminUserService.listUsers(cursor, Math.min(size, 60));
    }

    @Get("/admin/groups/{groupName}/users")
    public AdminCognitoUserPageDto listGroupUsers(
            @PathVariable String groupName,
            @Nullable @QueryValue String cursor,
            @QueryValue(defaultValue = "20") int size) {
        return adminUserService.listGroupUsers(groupName, cursor, Math.min(size, 60));
    }
}
