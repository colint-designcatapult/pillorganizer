package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.DeviceUserLinkEntity
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import jct.pillorganizer.global.repo.projection.UserAndDevicesViewRepo
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class DeviceUserLinkRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DeviceUserLinkRepo repo

    @Inject
    @Shared
    UserAndDevicesViewRepo userAndDevicesViewRepo

    def "should get DeviceUserLink by deviceId and userId"() {
        given:
        def deviceId = "device-1"
        def userId = "user-1"
        def tenantId = "tenant-1"
        def modelId = "MODEL-X"
        def isPrimary = true

        this.insertDeviceUserLink(deviceId, userId, tenantId, modelId, isPrimary)

        when:
        def link = repo.findByDeviceIdAndUserId(deviceId, userId)

        then:
        link.get().deviceId == deviceId
        link.get().userId == userId
        link.get().tenantId == tenantId
        link.get().modelId == modelId
        link.get().primaryUser == isPrimary
    }

    def "should get DeviceUserLinks by deviceId"() {
        given:
        def deviceId = "device-1"
        def userId1 = "user-1"
        def userId2 = "user-2"
        def tenantId = "tenant-1"
        def modelId = "MODEL-X"

        this.insertDeviceUserLink(deviceId, userId1, tenantId, modelId, true)
        this.insertDeviceUserLink(deviceId, userId2, tenantId, modelId, false)

        when:
        def links = repo.findByDeviceId(deviceId)

        then:
        links.size() == 2
        links.any { it.deviceId == deviceId && it.userId == userId1 }
        links.any { it.deviceId == deviceId && it.userId == userId2 }
    }

    def "should get DeviceUserLinks by userId"() {
        given:
        def deviceId1 = "device-1"
        def deviceId2 = "device-2"
        def userId = "user-1"
        def tenantId = "tenant-1"
        def modelId = "MODEL-X"

        this.insertDeviceUserLink(deviceId1, userId, tenantId, modelId, true)
        this.insertDeviceUserLink(deviceId2, userId, tenantId, modelId, false)

        when:
        def links = repo.findByUserId(userId)

        then:
        links.size() == 2
        links.any { it.deviceId == deviceId1 && it.userId == userId }
        links.any { it.deviceId == deviceId2 && it.userId == userId }
    }

    def "should save DeviceUserLink"() {
        given:
        def deviceId = "device-new"
        def userId = "user-new"
        def tenantId = "tenant-1"
        def modelId = "MODEL-Y"
        def isPrimary = true

        def link = DeviceUserLinkEntity.builder()
                .base(DeviceUserLinkEntity.buildBase(deviceId, userId))
                .deviceId(deviceId)
                .userId(userId)
                .tenantId(tenantId)
                .modelId(modelId)
                .primaryUser(isPrimary)
                .build()

        when:
        repo.save(link)

        then:
        def savedLink = repo.findByDeviceIdAndUserId(deviceId, userId)
        savedLink.get().deviceId == deviceId
        savedLink.get().userId == userId
        savedLink.get().tenantId == tenantId
        savedLink.get().modelId == modelId
        savedLink.get().primaryUser == isPrimary
        savedLink.get().base.entityType == DeviceControlPlaneEntityType.DEVICE_USER_LINK
    }

    def "should fail to find non-existent DeviceUserLink"() {
        when:
        def link = repo.findByDeviceIdAndUserId("device-does-not-exist", "user-does-not-exist")

        then:
        link.isEmpty()
    }

    def "should find user details and all devices for a user"() {
        given:
        def userId = "user-view-test"
        def deviceId1 = "device-view-1"
        def deviceId2 = "device-view-2"
        def tenantId = "tenant-1"
        def modelId = "MODEL-X"

        this.insertUser(userId, "Test User View", "sub-view-test")
        this.insertDeviceUserLink(deviceId1, userId, tenantId, modelId, true)
        this.insertDeviceUserLink(deviceId2, userId, tenantId, modelId, false)

        when:
        def views = userAndDevicesViewRepo.findAllByUserId(userId)

        then:
        views.size() == 3
        views.any { it.base.entityType == DeviceControlPlaneEntityType.USER && it.userName == "Test User View" }
        views.any { it.base.entityType == DeviceControlPlaneEntityType.DEVICE_USER_LINK && it.deviceId == deviceId1 }
        views.any { it.base.entityType == DeviceControlPlaneEntityType.DEVICE_USER_LINK && it.deviceId == deviceId2 }
    }
}
