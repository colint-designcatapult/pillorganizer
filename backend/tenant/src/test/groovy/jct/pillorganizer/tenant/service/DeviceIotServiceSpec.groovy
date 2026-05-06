package jct.pillorganizer.tenant.service

// @relation(CTRL-REQ-3, scope=file)
// @relation(UN-407, scope=file)
// @relation(UN-408, scope=file)
// @relation(SYS-REQ-14, scope=file)
// @relation(SYS-REQ-18, scope=file)
import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.tenant.model.device.LogicalDevice
import jct.pillorganizer.tenant.model.device.ProvisionRecord
import jct.pillorganizer.tenant.model.device.DeviceUser
import jct.pillorganizer.tenant.model.user.User
import spock.lang.Specification
import spock.lang.Subject

@MicronautTest
class DeviceIotServiceSpec extends Specification {

    @Inject
    @Subject
    DeviceIotService deviceIotService

    def "should generate properly formatted iot policy"() {
        given:
        def arnPrefix = deviceIotService.arnPrefix ?: "arn:aws:iot:region:account"
        def thingName = "test-thing-123"
        def userId = "user-abc"

        def pd = new ProvisionRecord(thingName: thingName)
        def d = new LogicalDevice(physicalDevice: pd)
        def u = new User(id: userId)
        def du = new DeviceUser(device: d, user: u)

        when:
        def policyJson = deviceIotService.generateDeviceUserAccessPolicyDocument(du)

        then:
        policyJson != null
        policyJson.contains('"Action":"iot:Connect"')
        policyJson.contains('"' + arnPrefix + ':client/' + thingName + '/user/' + userId + '"')
        policyJson.contains('"Action":"iot:Receive"')
        policyJson.contains('"' + arnPrefix + ':topic/healthe/things/' + thingName + '/*"')
        policyJson.contains('"' + arnPrefix + ':topic/$aws/things/' + thingName + '/shadow/*"')
        policyJson.contains('"Action":"iot:Subscribe"')
        policyJson.contains('"' + arnPrefix + ':topicfilter/healthe/things/' + thingName + '/*"')
        policyJson.contains('"' + arnPrefix + ':topicfilter/$aws/things/' + thingName + '/shadow/*"')
    }
}
