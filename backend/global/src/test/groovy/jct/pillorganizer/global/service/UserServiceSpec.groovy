package jct.pillorganizer.global.service

import io.micronaut.security.token.validator.TokenValidator
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.UserRepo
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException
import spock.lang.Specification
import spock.lang.Subject

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-5, scope=file)
// @relation(UN-301, scope=file)
// @relation(UN-302, scope=file)
// @relation(UN-306, scope=file)
// @relation(UN-7313, scope=file)
// @relation(SYS-REQ-22, scope=file)
// @relation(SYS-REQ-33, scope=file)
class UserServiceSpec extends Specification {

    UserRepo userRepo = Mock()
    KsuidService ksuidService = new KsuidService()
    TokenValidator<?> tokenValidator = Mock()
    NotificationEndpointService notificationEndpointService = Mock()

    @Subject
    UserService userService = new UserService(userRepo, ksuidService, tokenValidator, notificationEndpointService)

    def "should create a new user when one does not exist"() {
        given:
        def sub = "test-sub-1"
        def email = "test@example.com"

        and:
        userRepo.findBySub(sub) >> Optional.empty()

        when:
        def result = userService.createUser(sub, email)

        then:
        1 * userRepo.save(_) >> { UserEntity user ->
            assert user.userSub == sub
            assert user.email == email
            assert user.userId != null
        }
        result.userSub == sub
        result.email == email
        result.userId != null
    }

    def "should return existing user if already exists"() {
        given:
        def id = "test-id-2"
        def sub = "test-sub-2"
        def email = "test2@example.com"
        def existingUser = UserEntity.builder()
            .base(UserEntity.buildBase(id, sub))
            .userId(id)
            .email(email)
            .userSub(sub)
            .build()

        and:
        userRepo.findBySub(sub) >> Optional.of(existingUser)

        when:
        def result = userService.createUser(sub, email)

        then:
        0 * userRepo.save(_)
        result == existingUser
    }

    def "should handle concurrent creation gracefully"() {
        given:
        def id = "concurrent-id"
        def sub = "test-sub-3"
        def email = "test3@example.com"
        def existingUser = UserEntity.builder()
                .base(UserEntity.buildBase(id, sub))
                .userId(id)
                .email(email)
                .userSub(sub)
                .build()

        and:
        userRepo.findBySub(sub) >>> [Optional.empty(), Optional.of(existingUser)]
        userRepo.save(_) >> { throw ConditionalCheckFailedException.builder().build() }

        when:
        def result = userService.createUser(sub, email)

        then:
        result == existingUser
    }

    def "should throw exception if concurrent creation fails and user not found"() {
        given:
        def sub = "test-sub-4"
        def email = "test4@example.com"

        and:
        userRepo.findBySub(sub) >>> [Optional.empty(), Optional.empty()]
        userRepo.save(_) >> { throw ConditionalCheckFailedException.builder().build() }

        when:
        userService.createUser(sub, email)

        then:
        thrown(IllegalStateException)
    }

    def "registerFcmToken creates an endpoint ARN and persists it when none exists"() {
        given:
        def id = "user-fcm-1"
        def sub = "sub-fcm-1"
        def user = UserEntity.builder()
                .base(UserEntity.buildBase(id, sub))
                .userId(id).userSub(sub).email("fcm1@example.com")
                .build()
        def newArn = "arn:local:endpoint:1"

        and:
        notificationEndpointService.registerOrUpdateEndpoint("tok-abc", null) >> newArn

        when:
        def result = userService.registerFcmToken(user, "tok-abc")

        then:
        1 * userRepo.updateFcmEndpointArn(user, newArn)
        result.fcmEndpointArn == newArn
    }

    def "registerFcmToken is a no-op when the endpoint ARN is unchanged"() {
        given:
        def existingArn = "arn:local:endpoint:existing"
        def id = "user-fcm-2"
        def sub = "sub-fcm-2"
        def user = UserEntity.builder()
                .base(UserEntity.buildBase(id, sub))
                .userId(id).userSub(sub).email("fcm2@example.com")
                .fcmEndpointArn(existingArn)
                .build()

        and:
        notificationEndpointService.registerOrUpdateEndpoint("tok-same", existingArn) >> existingArn

        when:
        def result = userService.registerFcmToken(user, "tok-same")

        then:
        0 * userRepo.updateFcmEndpointArn(_, _)
        result.fcmEndpointArn == existingArn
    }
}
