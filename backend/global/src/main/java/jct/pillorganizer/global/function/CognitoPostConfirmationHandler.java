package jct.pillorganizer.global.function;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPostConfirmationEvent;
import io.micronaut.core.annotation.Introspected;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.service.UserService;

@Introspected
@Singleton
public class CognitoPostConfirmationHandler implements RequestHandler<CognitoUserPoolPostConfirmationEvent,
        CognitoUserPoolPostConfirmationEvent> {

    private final UserService userService;

    @Inject
    public CognitoPostConfirmationHandler(UserService userService) {
        this.userService = userService;
    }

    @Override
    public CognitoUserPoolPostConfirmationEvent handleRequest(CognitoUserPoolPostConfirmationEvent event, Context context) {
        String sub = event.getRequest().getUserAttributes().get("sub");
        String email = event.getRequest().getUserAttributes().get("email");

        userService.createUser(sub, email);

        return event;
    }
}
