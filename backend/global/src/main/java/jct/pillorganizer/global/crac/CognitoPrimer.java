package jct.pillorganizer.global.crac;

import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPostConfirmationEvent;
import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPreTokenGenerationEvent;
import io.micronaut.context.ApplicationContext;
import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.function.CognitoPostConfirmationHandler;
import jct.pillorganizer.global.function.CognitoPreTokenGenerationHandler;
import jct.pillorganizer.global.service.UserService;
import lombok.extern.flogger.Flogger;
import org.crac.Context;
import org.crac.Resource;

import java.util.Map;

@Flogger
@Singleton
@Requires(env = "lambda")
public class CognitoPrimer implements OrderedResource {

    private static final String TEST_EMAIL = "test-account-1@healthesolutions.ca";
    private static final String TEST_SUB = "0c8db568-3041-70a1-4263-1c9d5aa29ea6";

    private final CognitoPostConfirmationHandler postConfirmationHandler;
    private final CognitoPreTokenGenerationHandler preTokenGenerationHandler;

    @Inject
    public CognitoPrimer(ApplicationContext context, UserService userService) {
        this.postConfirmationHandler = new CognitoPostConfirmationHandler(context, userService);
        this.preTokenGenerationHandler = new CognitoPreTokenGenerationHandler(context, userService);
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        // Post user confirmation primer
        CognitoUserPoolPostConfirmationEvent postEvent = CognitoUserPoolPostConfirmationEvent.builder()
                .withRequest(CognitoUserPoolPostConfirmationEvent.Request.builder()
                        .withUserAttributes(Map.of("sub", TEST_SUB, "email", TEST_EMAIL))
                        .build())
                .build();
        CognitoUserPoolPostConfirmationEvent postResult = this.postConfirmationHandler.execute(postEvent);

        // Pre token primer
        CognitoUserPoolPreTokenGenerationEvent preEvent = CognitoUserPoolPreTokenGenerationEvent.builder()
                .withRequest(CognitoUserPoolPreTokenGenerationEvent.Request.builder()
                        .withUserAttributes(Map.of("sub", TEST_SUB, "email", TEST_EMAIL)).build())
                        .build();
        CognitoUserPoolPreTokenGenerationEvent preResullt = preTokenGenerationHandler.execute(preEvent);

        log.atInfo().log("Cognito primed: %s %s", postResult.getRequest().toString(),
                preResullt.getResponse().toString());
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {
    }
}
