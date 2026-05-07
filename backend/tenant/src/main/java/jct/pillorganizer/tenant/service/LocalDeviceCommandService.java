package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.DeviceCommandDto;
import lombok.extern.flogger.Flogger;

/**
 * Local / test implementation of {@link DeviceCommandService}.
 * Prints commands to console without sending MQTT messages.
 * Active in local and test environments.
 */
@Flogger
@Singleton
@Requires(env = {"local", "test"})
public class LocalDeviceCommandService implements DeviceCommandService {

    @Override
    public void sendCommand(String thingName, DeviceCommandDto command) {
        log.atInfo().log("Local: would send command to thing %s: type=%s reload=%s binId=%s binAction=%s",
                thingName,
                command.type(),
                command.reload(),
                command.binId(),
                command.binAction());
    }
}
