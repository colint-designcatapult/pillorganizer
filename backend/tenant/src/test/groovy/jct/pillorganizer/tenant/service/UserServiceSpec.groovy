package jct.pillorganizer.tenant.service

// @relation(CTRL-REQ-4, scope=file)
// @relation(UN-301, scope=file)
// @relation(UN-302, scope=file)
// @relation(UN-306, scope=file)
// @relation(SYS-REQ-22, scope=file)
import io.micronaut.data.exceptions.DataAccessException
import io.micronaut.retry.annotation.Retryable
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.user.User
import spock.lang.Subject

@MicronautTest
class UserServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    UserService userService

    def "upsert should create a new user if not exists"() {
        given:
        String userId = "user123"
        String name = "John Doe"
        String email = "john.doe@example.com"

        when:
        User result = userService.upsert(userId, name, email)

        then:
        result != null
        result.id == userId
        result.name == name
        result.email == email
    }

    def "upsert should create a new user if missing name"() {
        given:
        String userId = "user123"
        String email = "john.doe@example.com"

        when:
        User result = userService.upsert(userId, null, email)

        then:
        result != null
        result.id == userId
        result.name == null
        result.email == email
    }


    def "upsert should update existing user"() {
        given:
        String userId = "user456"
        String initialName = "Jane Doe"
        String initialEmail = "jane.doe@example.com"
        userService.upsert(userId, initialName, initialEmail)

        String newName = "Jane Smith"
        String newEmail = "jane.smith@example.com"

        when:
        User result = userService.upsert(userId, newName, newEmail)

        then:
        result != null
        result.id == userId
        result.name == newName
        result.email == newEmail
    }

    def "ensureExists should create user if not exists"() {
        given:
        String userId = "user789"

        when:
        User result = userService.ensureExists(userId)

        then:
        result != null
        result.id == userId
    }

    def "ensureExists should not modify existing user"() {
        given:
        String userId = "user101"
        String name = "Existing User"
        String email = "existing@example.com"
        userService.upsert(userId, name, email)

        when:
        User result = userService.ensureExists(userId)

        then:
        result != null
        result.id == userId

        and:
        Optional<User> retrievedUser = userService.get(userId)
        retrievedUser.isPresent()
        retrievedUser.get().name == name
        retrievedUser.get().email == email
    }

    def "get should return empty for non-existent user"() {
        given:
        String userId = "nonExistentUser"

        when:
        Optional<User> result = userService.get(userId)

        then:
        result.isEmpty()
    }

    def "get should return user for existing user"() {
        given:
        String userId = "user202"
        userService.ensureExists(userId)

        when:
        Optional<User> result = userService.get(userId)

        then:
        result.isPresent()
        result.get().id == userId
    }

    def "ensureExists should be retryable for data access conflicts"() {
        when:
        Retryable retryable = UserService.getDeclaredMethod("ensureExists", String).getAnnotation(Retryable)

        then:
        retryable != null
        DataAccessException in retryable.includes()
        retryable.attempts() == "5"
        retryable.delay() == "100ms"
        retryable.multiplier() == "2.0"
    }
}
