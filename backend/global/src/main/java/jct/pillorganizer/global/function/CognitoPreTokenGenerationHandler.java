package jct.pillorganizer.global.function;

import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPreTokenGenerationEvent;
import io.micronaut.context.ApplicationContext;
import io.micronaut.function.aws.MicronautRequestHandler;
import jakarta.inject.Inject;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.service.UserService;

import java.util.HashMap;
import java.util.Map;

public class CognitoPreTokenGenerationHandler extends MicronautRequestHandler<CognitoUserPoolPreTokenGenerationEvent, CognitoUserPoolPreTokenGenerationEvent> {

    @Inject
    UserService userService;

    public CognitoPreTokenGenerationHandler() {
        // Empty ctor for lambda
    }

    public CognitoPreTokenGenerationHandler(ApplicationContext context, UserService userService) {
        super(context);
        this.userService = userService;
    }

    @Override
    public CognitoUserPoolPreTokenGenerationEvent execute(CognitoUserPoolPreTokenGenerationEvent event) {
        String sub = event.getRequest().getUserAttributes().get("sub");
        String email = event.getRequest().getUserAttributes().get("email");

        UserEntity user = userService.getOrCreateUser(sub, email);

        Map<String, String> claimsToAddOrOverride = new HashMap<>();
        claimsToAddOrOverride.put("userId", user.getUserId());

        event.setResponse(CognitoUserPoolPreTokenGenerationEvent.Response.builder()
                .withClaimsOverrideDetails(CognitoUserPoolPreTokenGenerationEvent.ClaimsOverrideDetails.builder()
                        .withClaimsToAddOrOverride(claimsToAddOrOverride)
                        .build())
                .build());

        return event;
    }
}
