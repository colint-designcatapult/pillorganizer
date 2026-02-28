package jct.pillorganizer.tenant.service

import io.micronaut.test.annotation.MockBean
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.TenantDetails
import jct.pillorganizer.core.dto.DeviceAccessDto
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.dto.DeviceUserDTO
import jct.pillorganizer.tenant.model.device.Device
import jct.pillorganizer.tenant.model.user.User
import jct.pillorganizer.tenant.repo.DeviceRepository
import jct.pillorganizer.tenant.repo.UserRepository
import spock.lang.Subject

@MicronautTest
class DeviceUserServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    DeviceUserService deviceUserService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    UserRepository userRepository

    @Inject
    DeviceRepository deviceRepository

    @Inject
    TenantService tenantService

    @MockBean(TenantServiceImpl)
    TenantService tenantService() {
        Mock(TenantService)
    }

    def "addUserToDevice should link user to device"() {
        given:
        String userId = "user-link-1"
        String deviceId = "device-link-1"
        String serialNo = "SN-LINK-1"
        String claimToken = "token-link-1"

        User user = userService.upsert(userId, "Link User", "link@example.com")
        Device device = deviceService.create(deviceId, serialNo, claimToken)

        when:
        deviceUserService.addUserToDevice(user, device, true)

        then:
        deviceUserService.doesUserBelongToDevice(user, device)
        deviceUserService.userHasAccessToDevice(user, device)
    }

    def "addUserToDevice should be idempotent"() {
        given:
        String userId = "user-idem-1"
        String deviceId = "device-idem-1"
        String serialNo = "SN-IDEM-1"
        String claimToken = "token-idem-1"

        User user = userService.upsert(userId, "Idem User", "idem@example.com")
        Device device = deviceService.create(deviceId, serialNo, claimToken)

        when:
        deviceUserService.addUserToDevice(user, device, true)
        deviceUserService.addUserToDevice(user, device, true)

        then:
        deviceUserService.doesUserBelongToDevice(user, device)
    }

    def "getDevices should return linked devices"() {
        given:
        String userId = "user-get-1"
        String deviceId = "device-get-1"
        String serialNo = "SN-GET-1"
        String claimToken = "token-get-1"

        User user = userService.upsert(userId, "Get User", "get@example.com")
        Device device = deviceService.create(deviceId, serialNo, claimToken)
        deviceUserService.addUserToDevice(user, device, true)

        when:
        Set<DeviceUserDTO> devices = deviceUserService.getDevices(user)

        then:
        devices.size() == 1
        def dto = devices.first()
        dto.id() == deviceId
        dto.serialNo() == serialNo
        dto.primaryUser()
    }

    def "getDeviceAccess should return access details"() {
        given:
        String userId = "user-access-1"
        String deviceId = "device-access-1"
        String serialNo = "SN-ACCESS-1"
        String claimToken = "token-access-1"
        TenantDetails tenant = new TenantDetails("tenant-1", true, "api.tenant.com", "https://api.tenant.com",)

        User user = userService.upsert(userId, "Access User", "access@example.com")
        Device device = deviceService.create(deviceId, serialNo, claimToken)
        deviceUserService.addUserToDevice(user, device, true)

        and:
        tenantService.getCurrentTenant() >> Optional.of(tenant)

        when:
        def accessFlux = deviceUserService.getDeviceAccess(user)
        List<DeviceAccessDto> accessList = accessFlux.collectList().block()

        then:
        accessList.size() == 1
        def dto = accessList.first()
        dto.id() == deviceId
        dto.tenantId() == tenant.id
        dto.primaryUser()
    }
}
