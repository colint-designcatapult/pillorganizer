package jct.pillorganizer.global.function

import io.micronaut.context.ApplicationContext

// @relation(CTRL-REQ-2, scope=file)
// @relation(CTRL-REQ-3, scope=file)
// @relation(CTRL-REQ-27, scope=file)
// @relation(UN-302, scope=file)
// @relation(UN-602, scope=file)
// @relation(UN-7311, scope=file)
// @relation(SYS-REQ-14, scope=file)
// @relation(SYS-REQ-18, scope=file)
import io.micronaut.serde.ObjectMapper
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.function.type.IotCoreCustomAuthorizerEvent
import jct.pillorganizer.global.function.type.IotCoreCustomAuthorizerResponse
import jct.pillorganizer.global.function.type.IotCoreProtocolData
import jct.pillorganizer.global.function.type.IotCoreProtocolDataHttp
import jct.pillorganizer.global.function.type.IotCoreProtocolDataMqtt
import jct.pillorganizer.global.function.type.IotCoreConnectionMetadata
import jct.pillorganizer.global.service.IotAuthorizerService
import reactor.core.publisher.Mono
import io.micronaut.context.env.Environment
import spock.lang.Specification
import spock.lang.Subject

@MicronautTest
class IotCustomAuthorizerSpec extends Specification {

    IotAuthorizerService authorizerService = Mock()
    ObjectMapper objectMapper = Mock()

    @Inject
    ApplicationContext context

    @Subject
    IotCustomAuthorizer authorizer

    def setup() {
        authorizer = new IotCustomAuthorizer(context, authorizerService, objectMapper)
    }

    def "should deny access when protocol data is missing"() {
        given:
        def event = new IotCoreCustomAuthorizerEvent("token123", true, null, null, new IotCoreConnectionMetadata("connId"))

        when:
        def response = authorizer.execute(event)

        then:
        !response.isAuthenticated()
    }

    def "should deny access when HTTP data is missing"() {
        given:
        def protocolData = new IotCoreProtocolData(new IotCoreProtocolDataMqtt("user", "pass", "clientId"), null, null)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        def response = authorizer.execute(event)

        then:
        !response.isAuthenticated()
    }

    def "should deny access if JWT header is missing"() {
        given:
        def http = new IotCoreProtocolDataHttp("myQuery", Map.of("x-tenant-id", "tenant", "x-device-id", "device"))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        def response = authorizer.execute(event)

        then:
        !response.isAuthenticated()
    }

    def "should deny access if Tenant ID header is missing"() {
        given:
        def http = new IotCoreProtocolDataHttp("myQuery", Map.of("x-jwt", "jwt123", "x-device-id", "device"))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        def response = authorizer.execute(event)

        then:
        !response.isAuthenticated()
    }

    def "should deny access if Device ID header is missing"() {
        given:
        def http = new IotCoreProtocolDataHttp("myQuery", Map.of("x-tenant-id", "tenant", "x-jwt", "jwt123"))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        def response = authorizer.execute(event)

        then:
        !response.isAuthenticated()
    }

    def "should return valid Auth response when service returns success"() {
        given:
        def jwt = "myJwtToken"
        def tenant = "tenant-test"
        def device = "device-123"
        def principalId = "principal-user-1"
        def policy = "{\"Version\": \"2012-10-17\", \"Statement\": []}"

        def http = new IotCoreProtocolDataHttp("query", Map.of("x-jwt", jwt, "x-tenant-id", tenant, "x-device-id", device))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        def authorization = new IotAuthorizerService.IotAuthorization(principalId, [policy])
        
        when:
        def response = authorizer.execute(event)

        then:
        1 * authorizerService.authorizeIot(jwt, tenant, device) >> Mono.just(authorization)
        1 * objectMapper.writeValueAsString(_ as IotCoreCustomAuthorizerResponse) >> "{}"
        
        response.isAuthenticated()
        response.principalId() == principalId
        response.policyDocuments() == [policy]
        response.disconnectAfterInSeconds() == 3600
        response.refreshAfterInSeconds() == 300
    }

    def "should deny access when service returns empty Mono"() {
        given:
        def http = new IotCoreProtocolDataHttp("query", Map.of("x-jwt", "jwt", "x-tenant-id", "t", "x-device-id", "d"))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        def response = authorizer.execute(event)

        then:
        1 * authorizerService.authorizeIot("jwt", "t", "d") >> Mono.empty()
        
        !response.isAuthenticated()
        response.principalId() == null
        response.policyDocuments() == null
    }

    def "should bubble exception when service throws exception"() {
        given:
        def http = new IotCoreProtocolDataHttp("query", Map.of("x-jwt", "jwt", "x-tenant-id", "t", "x-device-id", "d"))
        def protocolData = new IotCoreProtocolData(null, null, http)
        def event = new IotCoreCustomAuthorizerEvent("token", true, null, protocolData, new IotCoreConnectionMetadata("conn"))

        when:
        authorizer.execute(event)

        then:
        1 * authorizerService.authorizeIot("jwt", "t", "d") >> Mono.error(new RuntimeException("Failure"))
        thrown(RuntimeException)
    }

    def "should deserialize IotCoreCustomAuthorizerEvent correctly"() {
        given:
        def realMapper = context.getBean(ObjectMapper)
        def json = """
        {
            "token": "tokxyz",
            "signatureVerified": true,
            "protocols": ["http"],
            "protocolData": {
                "http": {
                    "queryString": "q=1",
                    "headers": {
                        "x-jwt": "jwt123",
                        "x-tenant-id": "t1",
                        "x-device-id": "d1"
                    }
                }
            },
            "connectionMetadata": {
                "id": "conn123"
            }
        }
        """

        when:
        def event = realMapper.readValue(json, IotCoreCustomAuthorizerEvent)

        then:
        event.token() == "tokxyz"
        event.signatureVerified()
        event.protocols() == ["http"] as Set
        event.protocolData() != null
        event.protocolData().http() != null
        event.protocolData().http().queryString() == "q=1"
        event.protocolData().http().headers() == ["x-jwt": "jwt123", "x-tenant-id": "t1", "x-device-id": "d1"]
        event.connectionMetadata() != null
        event.connectionMetadata().id() == "conn123"
    }

}
