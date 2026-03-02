package jct.pillorganizer.global.service

import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.repo.UserRepo
import software.amazon.awssdk.services.dynamodb.model.ConditionalCheckFailedException
import spock.lang.Specification
import spock.lang.Subject

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-5, scope=file)
class UserServiceSpec extends Specification {

    UserRepo userRepo = Mock()
    KsuidService ksuidService = new KsuidService()

    @Subject
    UserService userService = new UserService(userRepo, ksuidService)

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
}
