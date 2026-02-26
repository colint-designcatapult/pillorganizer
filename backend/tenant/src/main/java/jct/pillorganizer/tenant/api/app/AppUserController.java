package jct.pillorganizer.tenant.api.app;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.MutableHttpResponse;
import io.micronaut.http.annotation.*;
import io.micronaut.multitenancy.Tenant;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.auth.AuthService;
import jct.pillorganizer.tenant.dto.*;
import jct.pillorganizer.tenant.model.user.AnonymousUser;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.model.user.UserRole;
import jct.pillorganizer.tenant.repo.AnonymousUserRepository;
import jct.pillorganizer.tenant.repo.UserRepository;
import org.zalando.problem.Problem;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import jakarta.validation.Valid;
import java.security.NoSuchAlgorithmException;
import java.security.Principal;
import java.security.SecureRandom;

@Controller("/api/v1/user")
public class AppUserController {

    @Inject
    UserRepository userRepo;

    @Inject
    AuthService authService;

    @Operation(summary = "Gets info about currently signed-in user")
    @Get("/me")
    @Secured({ "user", "anon" })
    public Mono<UserInfoDTO> authenticationStatus() {
        long userID = authService.getUserID();
        return userRepo.findUserInfoDTOFromID(userID);
    }

}
