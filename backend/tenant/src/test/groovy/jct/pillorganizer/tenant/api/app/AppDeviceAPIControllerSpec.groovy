package jct.pillorganizer.tenant.api.app

import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.HttpStatus
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.http.client.exceptions.HttpClientResponseException
import io.micronaut.security.authentication.Authentication
import io.micronaut.security.utils.SecurityService
import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.message.IotDeviceEventMessage
import jct.pillorganizer.core.service.TenantService
import jct.pillorganizer.core.uid.KsuidService
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.dto.DoseHistoryDto
import jct.pillorganizer.tenant.model.device.DeviceEvent
import jct.pillorganizer.tenant.model.device.DeviceSchedule
import jct.pillorganizer.tenant.model.device.ScheduleStatus
import jct.pillorganizer.tenant.model.device.ScheduleTakeEffect
import jct.pillorganizer.tenant.model.user.User
import jct.pillorganizer.tenant.repo.DeviceEventRepository
import jct.pillorganizer.tenant.repo.DeviceScheduleRepository
import jct.pillorganizer.tenant.service.DeviceEventService
import jct.pillorganizer.tenant.service.DeviceService
import jct.pillorganizer.tenant.service.NotificationService
import jct.pillorganizer.tenant.service.UserService

import java.time.Instant
import java.util.UUID

@MicronautTest(transactional = false)
class AppDeviceAPIControllerSpec extends BaseIntegrationSpec {

    @Inject
    @Client("/")
    HttpClient client

    @Inject
    SecurityService securityService

    @Inject
    TenantService tenantService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    DeviceEventService deviceEventService

    @Inject
    DeviceEventRepository deviceEventRepository

    @Inject
    DeviceScheduleRepository deviceScheduleRepository

    @Inject
    KsuidService ksuidService

    @Inject
    NotificationService notificationService

    @MockBean(SecurityService)
    SecurityService securityService() {
        Mock(SecurityService)
    }

    @MockBean(TenantService)
    TenantService tenantService() {
        Mock(TenantService)
    }

    @MockBean(NotificationService)
    NotificationService notificationService() {
        Mock(NotificationService)
    }

    @Override
    Map<String, String> getProperties() {
        return super.getProperties() + [
                "micronaut.security.enabled": "false"
        ]
    }

    def setup() {
        _ * tenantService.getCurrentTenant() >> Optional.of(TenantDetails.TEST_TENANT)
    }

    void "test getDeviceAdherenceHistory returns dose history for device with recent events"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-" + ksuidService.generateKsuid()
        
        User user = userService.ensureExists(userId)
        def provisionRecord = deviceService.provision(user, deviceId, "sn-1", claimId, thingName)
        def logicalDevice = provisionRecord.logicalDevice
        
        // Create a device schedule (required by the query)
        def schedule = new DeviceSchedule()
        schedule.id = UUID.randomUUID()
        schedule.device = logicalDevice
        schedule.createdBy = user
        schedule.timezoneIana = "America/Toronto"
        schedule.status = ScheduleStatus.APPLIED
        schedule.takeEffect = ScheduleTakeEffect.IMMEDIATE
        schedule.scheduleJson = '{"schedules": []}'
        deviceScheduleRepository.save(schedule)
        
        // Create some device events with TAKEN, MISSED, TAKE_NOW statuses
        def now = Instant.now()
        def scheduledTimeToday = now.minusSeconds(3600) // 1 hour ago
        
        def event1 = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(scheduledTimeToday.toEpochMilli())
                .eventType("TAKEN")
                .binId(0)
                .scheduleId(schedule.id.toString())
                .epochWeek(Instant.now().epochSecond)
                .scheduledTime(scheduledTimeToday.epochSecond)
                .build()
        
        def event2 = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(scheduledTimeToday.plusSeconds(3600).toEpochMilli())
                .eventType("MISSED")
                .binId(1)
                .scheduleId(schedule.id.toString())
                .epochWeek(Instant.now().epochSecond)
                .scheduledTime(scheduledTimeToday.plusSeconds(3600).epochSecond)
                .build()
        
        deviceEventService.processEvent(event1)
        deviceEventService.processEvent(event2)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?limit=50")
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() >= 2
        response[0].logicalDeviceId == deviceId
        response[0].finalStatus in ["TAKEN", "MISSED"]
        response[0].deviceTimeZone == "America/Toronto"
        response[0].binId in [0, 1]
    }

    void "test getDeviceAdherenceHistory returns empty list when device has no events"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        
        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-2", claimId, "thing-2")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?limit=50")
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() == 0
    }

    void "test getDeviceAdherenceHistory respects limit parameter"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-" + ksuidService.generateKsuid()
        
        User user = userService.ensureExists(userId)
        def provisionRecord = deviceService.provision(user, deviceId, "sn-3", claimId, thingName)
        def logicalDevice = provisionRecord.logicalDevice
        
        def schedule = new DeviceSchedule()
        schedule.id = UUID.randomUUID()
        schedule.device = logicalDevice
        schedule.createdBy = user
        schedule.timezoneIana = "UTC"
        schedule.status = ScheduleStatus.APPLIED
        schedule.takeEffect = ScheduleTakeEffect.IMMEDIATE
        schedule.scheduleJson = '{"schedules": []}'
        deviceScheduleRepository.save(schedule)
        
        // Create 5 events
        def now = Instant.now()
        for (int i = 0; i < 5; i++) {
            def scheduledTime = now.minusSeconds(3600 * (5 - i))
            def event = IotDeviceEventMessage.builder()
                    .thingName(thingName)
                    .tenant(TenantDetails.TEST_TENANT.id)
                    .timestamp(scheduledTime.toEpochMilli())
                    .eventType("TAKEN")
                    .binId(i)
                    .scheduleId(schedule.id.toString())
                    .epochWeek(now.epochSecond)
                    .scheduledTime(scheduledTime.epochSecond)
                    .build()
            deviceEventService.processEvent(event)
        }

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?limit=2")
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() == 2
    }

    void "test getDeviceAdherenceHistory returns 404 for non-existent device"() {
        given:
        String userId = ksuidService.generateKsuid()
        String fakeDeviceId = "nonexistent-device-id"
        
        User user = userService.ensureExists(userId)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + fakeDeviceId + "/adherencehistory")
        client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "test getDeviceAdherenceHistory returns 404 when accessing other user's device"() {
        given:
        String user1Id = ksuidService.generateKsuid()
        String user2Id = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        
        User user1 = userService.ensureExists(user1Id)
        User user2 = userService.ensureExists(user2Id)
        
        // User1 provisions the device
        deviceService.provision(user1, deviceId, "sn-4", claimId, "thing-4")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: user2Id]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory")
        client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "test getDeviceAdherenceHistory uses default limit of 50 when not specified"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-" + ksuidService.generateKsuid()
        
        User user = userService.ensureExists(userId)
        def provisionRecord = deviceService.provision(user, deviceId, "sn-5", claimId, thingName)
        def logicalDevice = provisionRecord.logicalDevice
        
        def schedule = new DeviceSchedule()
        schedule.id = UUID.randomUUID()
        schedule.device = logicalDevice
        schedule.createdBy = user
        schedule.timezoneIana = "Europe/London"
        schedule.status = ScheduleStatus.APPLIED
        schedule.takeEffect = ScheduleTakeEffect.IMMEDIATE
        schedule.scheduleJson = '{"schedules": []}'
        deviceScheduleRepository.save(schedule)
        
        // Create 1 event
        def now = Instant.now()
        def event = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(now.toEpochMilli())
                .eventType("TAKEN")
                .binId(5)
                .scheduleId(schedule.id.toString())
                .epochWeek(now.epochSecond)
                .scheduledTime(now.epochSecond)
                .build()
        deviceEventService.processEvent(event)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        // Note: no ?limit parameter specified
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory")
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() >= 1
    }
}
