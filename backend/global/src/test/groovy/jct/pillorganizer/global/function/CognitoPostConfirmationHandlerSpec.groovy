package jct.pillorganizer.global.function

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.events.CognitoUserPoolPostConfirmationEvent
import jakarta.inject.Inject
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.UserRepo
import spock.lang.Subject

// @relation(CTRL-REQ-4, scope=file)
class CognitoPostConfirmationHandlerSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    CognitoPostConfirmationHandler handler

    @Inject
    UserRepo userRepo

    def "should create a new user when one does not exist"() {
        given:
        def sub = "test-sub-1"
        def email = "test@example.com"
        def event = createEvent(sub, email)
        def context = Mock(Context)

        when:
        handler.handleRequest(event, context)

        then:
        def user = userRepo.findBySub(sub)
        user.isPresent()
        user.get().email == email
        user.get().userSub == sub
        user.get().userId != null
    }

    def "should be idempotent and return existing user if already exists"() {
        given:
        def sub = "test-sub-2"
        def email = "test2@example.com"
        def event = createEvent(sub, email)
        def context = Mock(Context)

        // Create the user first
        handler.handleRequest(event, context)
        def initialUser = userRepo.findBySub(sub).get()

        when:
        // Call handler again with same event
        handler.handleRequest(event, context)

        then:
        def user = userRepo.findBySub(sub)
        user.isPresent()
        user.get().userId == initialUser.userId
        user.get().email == email
        user.get().userId != null
    }

    def "should create different user IDs for different users"() {
        given:
        def sub1 = "test-sub-3"
        def email1 = "test3@example.com"
        def event1 = createEvent(sub1, email1)

        def sub2 = "test-sub-4"
        def email2 = "test4@example.com"
        def event2 = createEvent(sub2, email2)

        def context = Mock(Context)

        when:
        handler.handleRequest(event1, context)
        handler.handleRequest(event2, context)

        then:
        def user1 = userRepo.findBySub(sub1).get()
        def user2 = userRepo.findBySub(sub2).get()

        user1.userId != user2.userId
        user1.userSub == sub1
        user2.userSub == sub2
    }

    private CognitoUserPoolPostConfirmationEvent createEvent(String sub, String email) {
        return CognitoUserPoolPostConfirmationEvent.builder()
                .withRequest(CognitoUserPoolPostConfirmationEvent.Request.builder()
                        .withUserAttributes(["sub": sub, "email": email])
                        .build())
                .build()
    }
}
