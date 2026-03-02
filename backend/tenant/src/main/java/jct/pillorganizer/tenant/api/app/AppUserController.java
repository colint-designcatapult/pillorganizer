package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.*;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.projection.UserProfileView;
import jct.pillorganizer.tenant.repo.UserRepository;
import jct.pillorganizer.tenant.service.UserService;
import reactor.core.publisher.Mono;

import java.util.Optional;

@Controller("/api/v1/user")
public class AppUserController {

    @Inject
    UserService userService;

    @Operation(summary = "Gets the current user profile.")
    @Get("/me")
    public Optional<UserProfileView> authenticationStatus(User user) {
        return userService.getUserProfile(user.getId());
    }

}
