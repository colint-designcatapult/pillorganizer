package jct.pillorganizer.global.repo

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
}
