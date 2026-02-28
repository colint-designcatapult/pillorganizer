package jct.pillorganizer.tenant.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.message.BaseMessage;
import jct.pillorganizer.core.message.DeviceProvisionMessage;
import jct.pillorganizer.core.message.GrantUserMessage;
import jct.pillorganizer.tenant.model.user.User;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class QueueProcessorService {

    @Inject
    UserService userService;

    @Inject
    DeviceProvisionService provisionService;

    @Transactional
    public void processQueueMessage(BaseMessage message) throws Exception {
        if(message instanceof GrantUserMessage(String userId, String userName, String email)) {
            log.atInfo().log("Granting user %s", userId);
            userService.upsert(userId, userName, email);
        } else if (message instanceof DeviceProvisionMessage(String claimToken, String deviceId, String userId, String serialNo)) {
            log.atInfo().log("Provisioning %s to user %s", deviceId, userId);
            User user = userService.ensureExists(userId);
            provisionService.provision(user, deviceId, serialNo, claimToken);
        } else {
            throw new IllegalStateException("Invalid message: " + message.getType());
        }
    }

}
