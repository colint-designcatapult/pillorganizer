package jct.pillorganizer.global.function;

import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPostConfirmationEvent;
import io.micronaut.context.ApplicationContext;
import io.micronaut.function.aws.MicronautRequestHandler;
import jakarta.inject.Inject;
import jct.pillorganizer.global.service.UserService;

public class CognitoPostConfirmationHandler extends MicronautRequestHandler<CognitoUserPoolPostConfirmationEvent,
        CognitoUserPoolPostConfirmationEvent> {

    @Inject
    UserService userService;

    public CognitoPostConfirmationHandler() {
        // Empty ctor for lambda
    }

    @Inject
    public CognitoPostConfirmationHandler(ApplicationContext context, UserService userService) {
        super(context);
        this.userService = userService;
    }

    @Override
    public CognitoUserPoolPostConfirmationEvent execute(CognitoUserPoolPostConfirmationEvent event) {
        String sub = event.getRequest().getUserAttributes().get("sub");
        String email = event.getRequest().getUserAttributes().get("email");

        userService.createUser(sub, email);

        return event;
    }
}
