package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject

// @relation(CTRL-REQ-4, scope=file)
// @relation(CTRL-REQ-5, scope=file)
// @relation(UN-301, scope=file)
// @relation(UN-306, scope=file)
// @relation(SYS-REQ-22, scope=file)
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.UserEntity
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class UserRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    UserRepo repo

    def "should get User by id"() {
        given:
        def userId = "user-1"
        def userName = "Test User"
        def userSub = "sub-1"

        this.insertUser(userId, userName, userSub)

        when:
        def users = repo.findAllByUserId(userId)

        then:
        users.size() == 1
        users[0].userId == userId
        users[0].userName == userName
        users[0].userSub == userSub
    }

    def "should save User"() {
        given:
        def userId = "user-new"
        def userName = "New User"
        def userSub = "sub-new"

        def user = UserEntity.builder()
                .base(UserEntity.buildBase(userId, userSub))
                .userId(userId)
                .userName(userName)
                .userSub(userSub)
                .build()

        when:
        repo.save(user)

        then:
        def savedUsers = repo.findAllByUserId(userId)
        savedUsers.size() == 1
        savedUsers[0].userId == userId
        savedUsers[0].userName == userName
        savedUsers[0].userSub == userSub
        savedUsers[0].base.entityType == DeviceControlPlaneEntityType.USER
    }

    def "should fail to find non-existent User"() {
        when:
        def users = repo.findAllByUserId("user-does-not-exist")

        then:
        users.isEmpty()
    }

    def "should find User by sub"() {
        given:
        def userId = "user-sub-test"
        def userName = "Sub Test User"
        def userSub = "sub-test-1"

        this.insertUser(userId, userName, userSub)

        when:
        def user = repo.findBySub(userSub)

        then:
        user.isPresent()
        user.get().userId == userId
        user.get().userName == userName
        user.get().userSub == userSub
    }

    def "should fail to find User by non-existent sub"() {
        when:
        def user = repo.findBySub("sub-does-not-exist")

        then:
        user.isEmpty()
    }

    // ── findAllPaginated ──────────────────────────────────────────────────────

    def "findAllPaginated should return first page and a non-null cursor when more users exist"() {
        given: "three users whose GSI1_SK values sort as user-a < user-b < user-c"
        insertUser("user-a", "Alice", "sub-a")
        insertUser("user-b", "Bob",   "sub-b")
        insertUser("user-c", "Carol", "sub-c")

        when:
        def result = repo.findAllPaginated(2, null)

        then: "first page contains exactly 2 items"
        result.items().size() == 2

        and: "a cursor is returned because there is one more user"
        result.nextCursor() != null
    }

    def "findAllPaginated should return second page via cursor with no further cursor"() {
        given:
        insertUser("user-a", "Alice", "sub-a")
        insertUser("user-b", "Bob",   "sub-b")
        insertUser("user-c", "Carol", "sub-c")

        when:
        def page1 = repo.findAllPaginated(2, null)
        def page2 = repo.findAllPaginated(2, page1.nextCursor())

        then: "all three users are returned across two pages without overlap"
        def allIds = (page1.items() + page2.items()).collect { it.userId }
        allIds.size() == 3
        allIds.containsAll(["user-a", "user-b", "user-c"])

        and: "second page has the remaining 1 user and signals end-of-results"
        page2.items().size() == 1
        page2.nextCursor() == null
    }

    def "findAllPaginated should return null cursor when all users fit on a single page"() {
        given:
        insertUser("user-a", "Alice", "sub-a")
        insertUser("user-b", "Bob",   "sub-b")

        when:
        def result = repo.findAllPaginated(10, null)

        then:
        result.items().size() == 2
        result.nextCursor() == null
    }

    def "findAllPaginated should return empty list and null cursor when no users exist"() {
        when:
        def result = repo.findAllPaginated(20, null)

        then:
        result.items().isEmpty()
        result.nextCursor() == null
    }
}

