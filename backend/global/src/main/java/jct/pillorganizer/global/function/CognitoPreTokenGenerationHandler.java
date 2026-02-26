package jct.pillorganizer.global.function;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPreTokenGenerationEvent;
import io.micronaut.core.annotation.Introspected;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.UserRepo;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Introspected
@Singleton
public class CognitoPreTokenGenerationHandler implements RequestHandler<CognitoUserPoolPreTokenGenerationEvent, CognitoUserPoolPreTokenGenerationEvent> {

    private final UserRepo userRepo;

    @Inject
    public CognitoPreTokenGenerationHandler(UserRepo userRepo) {
        this.userRepo = userRepo;
    }

    @Override
    public CognitoUserPoolPreTokenGenerationEvent handleRequest(CognitoUserPoolPreTokenGenerationEvent event, Context context) {
        String sub = event.getRequest().getUserAttributes().get("sub");

        Optional<UserEntity> user = userRepo.findBySub(sub);

        if (user.isPresent()) {
            Map<String, String> claimsToAddOrOverride = new HashMap<>();
            claimsToAddOrOverride.put("userId", user.get().getUserId());

            event.setResponse(CognitoUserPoolPreTokenGenerationEvent.Response.builder()
                    .withClaimsOverrideDetails(CognitoUserPoolPreTokenGenerationEvent.ClaimsOverrideDetails.builder()
                            .withClaimsToAddOrOverride(claimsToAddOrOverride)
                            .build())
                    .build());
        }

        return event;
    }
}
