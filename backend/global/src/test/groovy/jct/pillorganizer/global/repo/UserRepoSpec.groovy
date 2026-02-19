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

        this.insertUser(userId, userName)

        when:
        def user = repo.findByUserId(userId)

        then:
        user.get().userId == userId
        user.get().userName == userName
    }

    def "should save User"() {
        given:
        def userId = "user-new"
        def userName = "New User"

        def user = UserEntity.builder()
                .base(UserEntity.buildBase(userId))
                .userId(userId)
                .userName(userName)
                .build()

        when:
        repo.save(user)

        then:
        def savedUser = repo.findByUserId(userId)
        savedUser.get().userId == userId
        savedUser.get().userName == userName
        savedUser.get().base.entityType == DeviceControlPlaneEntityType.USER
    }

    def "should fail to find non-existent User"() {
        when:
        def user = repo.findByUserId("user-does-not-exist")

        then:
        user.isEmpty()
    }
}
