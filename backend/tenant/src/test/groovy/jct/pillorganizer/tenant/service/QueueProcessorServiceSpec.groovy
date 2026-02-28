package jct.pillorganizer.tenant.service

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.core.message.DeviceProvisionMessage
import jct.pillorganizer.core.message.GrantUserMessage
import jct.pillorganizer.tenant.BaseIntegrationSpec
import jct.pillorganizer.tenant.model.device.Device
import jct.pillorganizer.tenant.model.user.User
import spock.lang.Subject

@MicronautTest
class QueueProcessorServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    QueueProcessorService queueProcessorService

    @Inject
    UserService userService

    @Inject
    DeviceService deviceService

    @Inject
    DeviceUserService deviceUserService

    def "processQueueMessage should handle GrantUserMessage"() {
        given:
        String userId = "user-grant-1"
        String userName = "Grant User"
        String email = "grant@example.com"
        GrantUserMessage message = new GrantUserMessage(userId, userName, email)

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        Optional<User> user = userService.get(userId)
        user.isPresent()
        user.get().name == userName
        user.get().email == email
    }

    def "processQueueMessage should handle DeviceProvisionMessage"() {
        given:
        String userId = "user-prov-1"
        String deviceId = "device-prov-1"
        String serialNo = "SN-PROV-1"
        String claimToken = "token-prov-1"
        
        // User must exist first for provision to work (as per implementation)
        User user = userService.upsert(userId, "Prov User", "prov@example.com")
        
        DeviceProvisionMessage message = new DeviceProvisionMessage(claimToken, deviceId, userId, serialNo)

        when:
        queueProcessorService.processQueueMessage(message)

        then:
        Device device = deviceService.findById(deviceId)
        device != null
        device.serialNo == serialNo
        
        and:
        deviceUserService.doesUserBelongToDevice(user, device)
    }

    def "processQueueMessage should throw exception for unknown message type"() {
        given:
        def unknownMessage = new jct.pillorganizer.core.message.BaseMessage() {
            @Override
            String getType() {
                return "UNKNOWN"
            }
        }

        when:
        queueProcessorService.processQueueMessage(unknownMessage)

        then:
        thrown(IllegalStateException)
    }
}
