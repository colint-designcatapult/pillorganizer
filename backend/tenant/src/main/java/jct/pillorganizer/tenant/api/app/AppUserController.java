package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.*;
import jct.pillorganizer.tenant.repo.UserRepository;
import reactor.core.publisher.Mono;

@Controller("/api/v1/user")
public class AppUserController {

    @Inject
    UserRepository userRepo;

    @Inject
    AuthService authService;

    @Operation(summary = "Gets info about currently signed-in user")
    @Get("/me")
    @Secured({ "user", "anon" })
    public UserInfoDTO authenticationStatus() {
        String userID = authService.getUserID();
        return userRepo.findUserInfoDTOFromID(userID);
    }

}
