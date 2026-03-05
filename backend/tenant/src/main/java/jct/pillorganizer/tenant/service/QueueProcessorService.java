package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.message.BaseMessage;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class QueueProcessorService {

    @Inject
    UserService userService;

    @Inject
    DeviceProvisionService provisionService;

    private void deviceProvision(DeviceProvisionMessage message) {
        // Ensure the user exists
        User user = userService.ensureExists(message.userId());

        // Create the provisioning record
        ProvisionRecord provisionRecord = provisionService.provision(user, message.deviceId(), message.serialNo(),
                message.claimId(), message.thingName());

        log.atInfo().log("Provisioning record saved, device %s user %s claim %s",
                provisionRecord.getLogicalDevice().getId(), provisionRecord.getProvisionedBy().getId(),
                provisionRecord.getClaimId());
    }

    private void grantUser(GrantUserMessage message) {
        log.atInfo().log("Granting new user %s", message.userId());
        userService.upsert(message.userId(), message.userName(), message.email());
    }

    @Transactional
    public void processQueueMessage(BaseMessage message) throws Exception {
        if(message instanceof GrantUserMessage) {
            grantUser((GrantUserMessage) message);
        } else if (message instanceof DeviceProvisionMessage) {
            deviceProvision((DeviceProvisionMessage) message);
        } else {
            throw new IllegalStateException("Invalid message: " + message.getType());
        }
    }

}
