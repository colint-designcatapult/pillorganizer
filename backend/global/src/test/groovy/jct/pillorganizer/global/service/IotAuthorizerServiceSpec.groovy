package jct.pillorganizer.global.service

import jct.pillorganizer.global.exception.DeviceAccessException
import jct.pillorganizer.global.model.DeviceEntity
import jct.pillorganizer.global.model.UserEntity
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import spock.lang.Specification
import spock.lang.Subject

import io.micronaut.security.authentication.AuthenticationException

class IotAuthorizerServiceSpec extends Specification {

    UserService userService = Mock()
    UserDeviceAccessService userDeviceAccessService = Mock()
    DeviceService deviceService = Mock()

    @Subject
    IotAuthorizerService service

    def setup() {
        service = new IotAuthorizerService()
        service.userService = userService
        service.userDeviceAccessService = userDeviceAccessService
        service.deviceService = deviceService
        service.arnPrefix = "arn:aws:iot:us-east-1:123456789012"
    }

    def "should authorize IoT successfully"() {
        given:
        def jwt = "valid-jwt"
        def tenantId = "tenant-1"
        def deviceId = "device-1"
        def userId = "user-123"

        def deviceEntity = DeviceEntity.builder()
                .deviceId(deviceId)
                .tenantId(tenantId)
                .thingName("tenant-1-sn-1-device-1")
                .build()

        def userEntity = UserEntity.builder()
                .userId(userId)
                .userSub("sub-123")
                .build()

        def mockPolicy = "{\"Statement\":[{\"Action\":\"iot:Connect\",\"Effect\":\"Allow\"}]}"

        deviceService.getDevice(deviceId) >> Optional.of(deviceEntity)
        userService.authenticateJwt(jwt) >> Mono.just(userEntity)
        userDeviceAccessService.getUserDeviceAccessPolicyDocument(jwt, tenantId, deviceId) >> Mono.just(mockPolicy)

        when:
        def result = service.authorizeIot(jwt, tenantId, deviceId).block()

        then:
        result != null
        result.principalId() == "USER" + userId
        result.policyDocument().size() == 3
        result.policyDocument()[0] == mockPolicy
        result.policyDocument()[1].contains("Deny") // tenant isolation
        result.policyDocument()[2].contains("Deny") // device isolation
    }

    def "should throw DeviceAccessException when device ID does not exist"() {
        given:
        def jwt = "valid-jwt"
        def tenantId = "tenant-1"
        def deviceId = "missing-device"

        deviceService.getDevice(deviceId) >> Optional.empty()

        when:
        service.authorizeIot(jwt, tenantId, deviceId).block()

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Invalid device ID"
    }

    def "should throw DeviceAccessException when requested tenant does not match device tenant"() {
        given:
        def jwt = "valid-jwt"
        def requestedTenantId = "tenant-hacker"
        def actualTenantId = "tenant-1"
        def deviceId = "device-1"

        def deviceEntity = DeviceEntity.builder()
                .deviceId(deviceId)
                .tenantId(actualTenantId)
                .build()

        deviceService.getDevice(deviceId) >> Optional.of(deviceEntity)

        when:
        service.authorizeIot(jwt, requestedTenantId, deviceId).block()

        then:
        def e = thrown(DeviceAccessException)
        e.message == "Invalid tenant ID"
    }

    def "should bubble up Exception when authenticateJwt fails"() {
        given:
        def jwt = "invalid-jwt"
        def tenantId = "tenant-1"
        def deviceId = "device-1"

        def deviceEntity = DeviceEntity.builder()
                .deviceId(deviceId)
                .tenantId(tenantId)
                .build()

        deviceService.getDevice(deviceId) >> Optional.of(deviceEntity)
        userService.authenticateJwt(jwt) >> Mono.error(new AuthenticationException("Invalid Token"))
        userDeviceAccessService.getUserDeviceAccessPolicyDocument(jwt, tenantId, deviceId) >> Mono.just("policy")

        when:
        def mono = service.authorizeIot(jwt, tenantId, deviceId)

        then:
        StepVerifier.create(mono)
                .expectError(AuthenticationException)
                .verify()
    }

    def "should bubble up Exception when getUserDeviceAccessPolicyDocument fails"() {
        given:
        def jwt = "valid-jwt"
        def tenantId = "tenant-1"
        def deviceId = "device-1"
        def userId = "user-123"

        def deviceEntity = DeviceEntity.builder()
                .deviceId(deviceId)
                .tenantId(tenantId)
                .build()

        def userEntity = UserEntity.builder()
                .userId(userId)
                .build()

        deviceService.getDevice(deviceId) >> Optional.of(deviceEntity)
        userService.authenticateJwt(jwt) >> Mono.just(userEntity)
        userDeviceAccessService.getUserDeviceAccessPolicyDocument(jwt, tenantId, deviceId) >> Mono.error(new DeviceAccessException("No access"))

        when:
        def mono = service.authorizeIot(jwt, tenantId, deviceId)

        then:
        StepVerifier.create(mono)
                .expectError(DeviceAccessException)
                .verify()
    }

    def "should generate tenant isolation policy covering all required resources"() {
        given:
        def tenantId = "tenant-isolation-test"

        when:
        def policy = service.generateTenantIsolationPolicy(tenantId)

        then:
        policy.contains("\"Effect\":\"Deny\"")
        policy.contains("arn:aws:iot:us-east-1:123456789012:client/tenant-isolation-test-*")
        policy.contains("arn:aws:iot:us-east-1:123456789012:topic/healthe/things/tenant-isolation-test-*")
    }

    def "should generate device isolation policy covering all required resources"() {
        given:
        def userId = "user-123"
        def thingName = "tenant-1-sn-1-device-1"
        def deviceEntity = DeviceEntity.builder()
                .thingName(thingName)
                .build()

        when:
        def policy = service.generateDevicePolicy(deviceEntity, userId)

        then:
        policy.contains("\"Effect\":\"Deny\"")
        policy.contains("arn:aws:iot:us-east-1:123456789012:client/tenant-1-sn-1-device-1/user/user-123")
        policy.contains("arn:aws:iot:us-east-1:123456789012:topic/healthe/things/tenant-1-sn-1-device-1")
    }
}
