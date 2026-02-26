package jct.pillorganizer.global.function

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPreTokenGenerationEvent
import io.micronaut.context.ApplicationContext
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.UserRepo
import jct.pillorganizer.global.service.UserService
import spock.lang.Specification
import spock.lang.Subject

// @relation(CTRL-REQ-7, scope=file)
@MicronautTest
class CognitoPreTokenGenerationHandlerSpec extends BaseIntegrationSpec {

    @Subject
    CognitoPreTokenGenerationHandler handler

    @Inject
    ApplicationContext context

    @Inject
    UserService userService

    @Inject
    UserRepo userRepo

    def setup() {
        handler = new CognitoPreTokenGenerationHandler(context, userService)
    }

    def "should inject userId into ID token claims"() {
        given:
        def sub = "test-sub-pre-token"
        def email = "test-pre-token@example.com"
        def user = userService.createUser(sub, email)
        def event = createEvent(sub, email)
        def context = Mock(Context)

        when:
        def response = handler.handleRequest(event, context)

        then:
        response.response.claimsOverrideDetails.claimsToAddOrOverride["userId"] == user.userId
    }

    def "should create user and inject userId if user not found"() {
        given:
        def sub = "non-existent-sub"
        def email = "non-existent@example.com"
        def event = createEvent(sub, email)
        def context = Mock(Context)

        when:
        def response = handler.handleRequest(event, context)

        then:
        response.response.claimsOverrideDetails.claimsToAddOrOverride["userId"] != null
        def user = userRepo.findBySub(sub).get()
        user.email == email
        response.response.claimsOverrideDetails.claimsToAddOrOverride["userId"] == user.userId
    }

    private CognitoUserPoolPreTokenGenerationEvent createEvent(String sub, String email) {
        return CognitoUserPoolPreTokenGenerationEvent.builder()
                .withRequest(CognitoUserPoolPreTokenGenerationEvent.Request.builder()
                        .withUserAttributes(["sub": sub, "email": email])
                        .build())
                .build()
    }
}
