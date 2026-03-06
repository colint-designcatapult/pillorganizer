package jct.pillorganizer.global.crac;

import io.micronaut.context.ApplicationContext;
import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import io.micronaut.security.authentication.Authentication;
import io.micronaut.security.token.validator.TokenValidator;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.function.CognitoPostConfirmationHandler;
import jct.pillorganizer.global.function.CognitoPreTokenGenerationHandler;
import jct.pillorganizer.global.model.DeviceClaimEntity;
import jct.pillorganizer.global.repo.DeviceClaimRepo;
import jct.pillorganizer.global.service.DeviceService;
import jct.pillorganizer.global.service.IotAuthorizerService;
import jct.pillorganizer.global.service.TenantMessageService;
import jct.pillorganizer.global.service.UserService;
import lombok.extern.flogger.Flogger;
import org.crac.Context;
import org.crac.Resource;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Optional;

@Flogger
@Singleton
@Requires(env = "lambda")
public class IotCorePrimer implements OrderedResource {
    @Inject
    DeviceClaimRepo deviceClaimRepo;
    @Inject
    DeviceService deviceService;
    @Inject
    TenantMessageService messageService;
    @Inject
    TokenValidator<?> tokenValidator;

    private static final String JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZS" +
            "I6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE4OTM0NTYwMDB9.i5j8n8GqR2l9Q-5_5d2xU4zE_QGz_882W8S5WJtq" +
            "G5I";

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        Optional<DeviceClaimEntity> entity = deviceClaimRepo.findBySerialNumberAndClaimId(
                "SN-DOES-NOT-EXIST", "CLAIM-DOES-NOT-EXIST");
        String tenant = deviceService.lookupTenant("SN-DOES-NOT-EXIST");
        try {
            messageService.primeService(tenant);
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Failed to prime tenant message service");
        }

        try {
            Optional<Authentication> auth = Mono.from(tokenValidator.validateToken(JWT_TOKEN, null))
                    .blockOptional(Duration.ofSeconds(5));
            log.atInfo().log("Primed token validator: %s", auth.toString());
        } catch (Exception ex) {
            log.atInfo().withCause(ex).log("Failed to prime token validator");
        }

        log.atInfo().log("IoT Core primed: %s", entity.toString());
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
