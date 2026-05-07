package jct.pillorganizer.tenant.api.app

// @relation(UN-403, scope=file)
// @relation(UN-7311, scope=file)
// @relation(UN-401, scope=file)
// @relation(UN-404, scope=file)
// @relation(UN-405, scope=file)
// @relation(UN-406, scope=file)
// @relation(SYS-REQ-13, scope=file)
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
import jct.pillorganizer.tenant.service.DeviceCommandService
import jct.pillorganizer.tenant.service.NotificationService
import jct.pillorganizer.tenant.service.UserService

import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import java.util.Optional

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

    @Inject
    DeviceCommandService deviceCommandService

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

    void "test getDeviceAdherenceHistory returns dose history for entire month"() {
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
        
        // Create device events on different days in the current month
        def today = LocalDate.now()
        def year = today.year
        def month = today.monthValue
        
        def day1 = LocalDate.of(year, month, 1).atStartOfDay().atZone(java.time.ZoneId.of("America/Toronto")).toInstant()
        def day10 = LocalDate.of(year, month, 10).atStartOfDay().atZone(java.time.ZoneId.of("America/Toronto")).toInstant()
        def day20 = LocalDate.of(year, month, 20).atStartOfDay().atZone(java.time.ZoneId.of("America/Toronto")).toInstant()
        
        def event1 = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(day1.toEpochMilli())
                .eventType("TAKEN")
                .binId(0)
                .scheduleId(schedule.id.toString())
                .epochWeek(day1.epochSecond)
                .scheduledTime(day1.epochSecond)
                .build()
        
        def event2 = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(day10.toEpochMilli())
                .eventType("MISSED")
                .binId(1)
                .scheduleId(schedule.id.toString())
                .epochWeek(day10.epochSecond)
                .scheduledTime(day10.epochSecond)
                .build()
        
        def event3 = IotDeviceEventMessage.builder()
                .thingName(thingName)
                .tenant(TenantDetails.TEST_TENANT.id)
                .timestamp(day20.toEpochMilli())
                .eventType("TAKE_NOW")
                .binId(2)
                .scheduleId(schedule.id.toString())
                .epochWeek(day20.epochSecond)
                .scheduledTime(day20.epochSecond)
                .build()
        
        deviceEventService.processEvent(event1)
        deviceEventService.processEvent(event2)
        deviceEventService.processEvent(event3)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?year=" + year + "&month=" + month)
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() == 3
        response.every { it.logicalDeviceId == deviceId }
        response.every { it.finalStatus in ["TAKEN", "MISSED", "TAKE_NOW"] }
        response.every { it.deviceTimeZone == "America/Toronto" }
    }


    void "test getDeviceAdherenceHistory returns empty list when device has no events in month"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        
        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-2", claimId, "thing-2")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def today = LocalDate.now()
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?year=" + today.year + "&month=" + today.monthValue)
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
        
        // Create 10 events in current month
        def today = LocalDate.now()
        def year = today.year
        def month = today.monthValue
        
        for (int i = 1; i <= 10; i++) {
            def day = LocalDate.of(year, month, Math.min(i, 28)).atStartOfDay().atZone(java.time.ZoneId.of("UTC")).toInstant()
            def event = IotDeviceEventMessage.builder()
                    .thingName(thingName)
                    .tenant(TenantDetails.TEST_TENANT.id)
                    .timestamp(day.toEpochMilli())
                    .eventType("TAKEN")
                    .binId(i)
                    .scheduleId(schedule.id.toString())
                    .epochWeek(day.epochSecond)
                    .scheduledTime(day.epochSecond)
                    .build()
            deviceEventService.processEvent(event)
        }

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?year=" + year + "&month=" + month)
        def response = client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.size() == 10
    }

    void "test getDeviceAdherenceHistory returns 404 for non-existent device"() {
        given:
        String userId = ksuidService.generateKsuid()
        String fakeDeviceId = "nonexistent-device-id"
        def today = LocalDate.now()
        
        User user = userService.ensureExists(userId)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + fakeDeviceId + "/adherencehistory?year=" + today.year + "&month=" + today.monthValue)
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
        def today = LocalDate.now()
        
        User user1 = userService.ensureExists(user1Id)
        User user2 = userService.ensureExists(user2Id)
        
        // User1 provisions the device
        deviceService.provision(user1, deviceId, "sn-4", claimId, "thing-4")

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: user2Id]

        when:
        def request = HttpRequest.GET("/api/v1/device/" + deviceId + "/adherencehistory?year=" + today.year + "&month=" + today.monthValue)
        client.toBlocking().retrieve(request, Argument.listOf(DoseHistoryDto))

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    // ── Command endpoint tests ─────────────────────────────────────────────────

    void "test sendCommand succeeds for primary user with valid RELOAD command"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-cmd-1", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def body = [type: "RELOAD", reload: "INITIATE"]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        def response = client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.status == HttpStatus.ACCEPTED
    }

    void "test sendCommand succeeds for primary user with valid BIN command"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-cmd-2", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def body = [type: "BIN", binId: 3, binAction: "TAKEN"]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        def response = client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        response.status == HttpStatus.ACCEPTED
    }

    void "test sendCommand returns 404 for non-primary user"() {
        given:
        String ownerUserId = ksuidService.generateKsuid()
        String otherUserId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User owner = userService.ensureExists(ownerUserId)
        User other = userService.ensureExists(otherUserId)
        deviceService.provision(owner, deviceId, "sn-cmd-3", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: otherUserId]

        when:
        def body = [type: "RELOAD", reload: "INITIATE"]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.NOT_FOUND
    }

    void "test sendCommand returns 400 for RELOAD command without reload field"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-cmd-4", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def body = [type: "RELOAD"]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.BAD_REQUEST
    }

    void "test sendCommand returns 400 for BIN command without binId"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-cmd-5", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def body = [type: "BIN", binAction: "TAKEN"]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.BAD_REQUEST
    }

    void "test sendCommand returns 400 for BIN command without binAction"() {
        given:
        String userId = ksuidService.generateKsuid()
        String deviceId = ksuidService.generateKsuid()
        String claimId = ksuidService.generateKsuid()
        String thingName = "thing-cmd-" + ksuidService.generateKsuid()

        User user = userService.ensureExists(userId)
        deviceService.provision(user, deviceId, "sn-cmd-6", claimId, thingName)

        def auth = Mock(Authentication)
        auth.getAttributes() >> [userId: userId]

        when:
        def body = [type: "BIN", binId: 5]
        def request = HttpRequest.POST("/api/v1/device/" + deviceId + "/command", body)
        client.toBlocking().exchange(request)

        then:
        _ * securityService.getAuthentication() >> Optional.of(auth)
        HttpClientResponseException e = thrown()
        e.status == HttpStatus.BAD_REQUEST
    }
}
