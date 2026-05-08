package jct.pillorganizer.tenant.service;

import io.micronaut.core.type.Argument;
import io.micronaut.data.exceptions.DataAccessException;
import io.micronaut.json.JsonMapper;
import io.micronaut.retry.annotation.Retryable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.core.dto.ShadowStateDto;
import jct.pillorganizer.core.message.*;
import jct.pillorganizer.tenant.dto.DeviceScheduleDTO;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.device.ProvisionRecord;
import jct.pillorganizer.tenant.model.user.User;
import jct.pillorganizer.tenant.repo.UserRepository;
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
    DeviceEventService deviceEventService;

    @Inject
    JsonMapper jsonMapper;

    @Inject
    UserRepository userRepository;

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

            Object currentState = message.current();
            if (currentState == null) {
                log.atWarning().log(
                        "Missing current shadow state for thing %s and shadow %s; skipping processing.",
                        message.thingName(),
                        message.shadowName()
                );
                return;
            }

            try {
                Argument<ShadowStateDto> targetType =
                        Argument.of(ShadowStateDto.class, DeviceScheduleDTO.class);

                byte[] rawDataBytes = jsonMapper.writeValueAsBytes(currentState);
                ShadowStateDto<DeviceScheduleDTO> result = jsonMapper.readValue(rawDataBytes, targetType);

                scheduleService.processScheduleDocument(message.thingName(), result);
            } catch (Exception e) {
                log.atWarning().withCause(e).log("Failed to parse shadow state for: %s", message.thingName());
            }

        } else {
            log.atWarning().log("Could not process shadow document for unknown named shadow: %s", message.shadowName());
        }
    }

    private void deviceEvent(IotDeviceEventMessage message) {
        deviceEventService.processEvent(message);
    }

    @Transactional
    private void deleteUser(DeleteUserMessage message) {
        log.atInfo().log("Processing deleteUser for user %s", message.userId());

        User user = userService.get(message.userId()).orElse(null);
        if (user == null) {
            log.atWarning().log("User %s not found, skipping deleteUser", message.userId());
            return;
        }

        // Iterate through user's devices and perform removal
        java.util.List<DeviceUser> deviceUsers = user.getDevices();
        if (deviceUsers != null) {
            for (DeviceUser du : deviceUsers) {
                deviceService.removeDevice(user, du.getDevice());
            }
        }

        // Clear name/email and set disabledAt
        userRepository.disableUser(user.getId());
        log.atInfo().log("Disabled user %s", user.getId());
    }

    @Retryable(
            includes = DataAccessException.class,
            delay = "100ms",
            multiplier = "2.0"
    )
    public void processQueueMessage(BaseMessage message) throws Exception {
        if(message instanceof GrantUserMessage) {
            grantUser((GrantUserMessage) message);
        } else if (message instanceof DeviceProvisionMessage) {
            deviceProvision((DeviceProvisionMessage) message);
        } else if(message instanceof IotShadowStateMessage) {
            shadowStateDocument((IotShadowStateMessage) message);
        } else if(message instanceof IotDeviceEventMessage) {
            deviceEvent((IotDeviceEventMessage) message);
        } else if(message instanceof NoOpMessage) {
            // do nothing
            log.atInfo().log("Processing noop queue message");
        } else if(message instanceof DeleteUserMessage) {
            deleteUser((DeleteUserMessage) message);
        } else {
            throw new IllegalStateException("Invalid message: " + message.getType());
        }
    }

}
