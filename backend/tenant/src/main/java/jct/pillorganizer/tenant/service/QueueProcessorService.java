package jct.pillorganizer.tenant.service;

import io.micronaut.core.type.Argument;
import io.micronaut.json.JsonMapper;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.ShadowStateDto;
import jct.pillorganizer.core.message.*;
import jct.pillorganizer.tenant.dto.DeviceScheduleDTO;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class QueueProcessorService {

    @Inject
    UserService userService;

    @Inject
    DeviceService deviceService;

    @Inject
    ScheduleService scheduleService;

    @Inject
    JsonMapper jsonMapper;

    private void deviceProvision(DeviceProvisionMessage message) {
        // Ensure the user exists
        User user = userService.ensureExists(message.userId());

        // Create the provisioning record
        ProvisionRecord provisionRecord = deviceService.provision(user, message.deviceId(), message.serialNo(),
                message.claimId(), message.thingName());

        log.atInfo().log("Provisioning record saved, device %s user %s claim %s",
                provisionRecord.getLogicalDevice().getId(), provisionRecord.getProvisionedBy().getId(),
                provisionRecord.getClaimId());
    }

    private void grantUser(GrantUserMessage message) {
        log.atInfo().log("Granting new user %s", message.userId());
        userService.upsert(message.userId(), message.userName(), message.email());
    }

    private void shadowStateDocument(IotShadowStateMessage message) {
        if(IotShadowService.SCHEDULE_SHADOW.equals(message.shadowName())) {

            try {
                Argument<ShadowStateDto> targetType =
                        Argument.of(ShadowStateDto.class, DeviceScheduleDTO.class);

                byte[] rawDataBytes = jsonMapper.writeValueAsBytes(message.current());
                ShadowStateDto<DeviceScheduleDTO> result = jsonMapper.readValue(rawDataBytes, targetType);

                scheduleService.processScheduleDocument(message.thingName(), result);
            } catch (Exception e) {
                log.atWarning().withCause(e).log("Failed to parse shadow state for: %s", message.thingName());
            }

        } else {
            log.atWarning().log("Could not process shadow document for unknown named shadow: %s", message.shadowName());
        }
    }

    @Transactional
    public void processQueueMessage(BaseMessage message) throws Exception {
        if(message instanceof GrantUserMessage) {
            grantUser((GrantUserMessage) message);
        } else if (message instanceof DeviceProvisionMessage) {
            deviceProvision((DeviceProvisionMessage) message);
        } else if(message instanceof IotShadowStateMessage) {
            shadowStateDocument((IotShadowStateMessage) message);
        } else if(message instanceof NoOpMessage) {
            // do nothing
            log.atInfo().log("Processing noop queue message");
        } else {
            throw new IllegalStateException("Invalid message: " + message.getType());
        }
    }

}
