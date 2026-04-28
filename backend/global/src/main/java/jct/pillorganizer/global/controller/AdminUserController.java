package jct.pillorganizer.global.controller;

import io.micronaut.core.annotation.Blocking;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.http.HttpStatus;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.global.dto.AdminDeviceSummaryDto;
import jct.pillorganizer.global.dto.AdminUserDetailDto;
import jct.pillorganizer.global.dto.AdminUserPageDto;
import jct.pillorganizer.global.dto.AdminUserSummaryDto;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.repo.PageResult;
import jct.pillorganizer.global.repo.UserRepo;

import java.util.List;
import java.util.stream.Collectors;

@Controller("/admin/users")
@Secured(AppSecurityRule.IS_GLOBAL_ADMIN)
@Blocking
public class AdminUserController {

    @Inject
    UserRepo userRepo;

    @Inject
    DeviceClaimRepo deviceClaimRepo;

    @Get
    public AdminUserPageDto listUsers(
            @Nullable @QueryValue String cursor,
            @Nullable @QueryValue String userIdFilter,
            @QueryValue(defaultValue = "20") int size) {
        PageResult<UserEntity> result = userRepo.findAllPaginated(size, cursor, userIdFilter);
        List<AdminUserSummaryDto> items = result.items().stream()
                .map(AdminUserSummaryDto::from)
                .collect(Collectors.toList());
        return new AdminUserPageDto(items, result.nextCursor());
    }

    @Get("/{userId}")
    public AdminUserDetailDto getUser(@PathVariable String userId) {
        UserEntity user = userRepo.findAllByUserId(userId)
                .stream()
                .findFirst()
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND, "User not found: " + userId));

        List<AdminDeviceSummaryDto> devices = deviceClaimRepo.findAllByUserId(userId)
                .stream()
                .map(AdminDeviceSummaryDto::fromClaim)
                .collect(Collectors.toList());

        return AdminUserDetailDto.from(user, devices);
    }
}

