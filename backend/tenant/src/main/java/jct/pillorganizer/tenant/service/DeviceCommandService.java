package jct.pillorganizer.tenant.service;

import jct.pillorganizer.tenant.dto.DeviceCommandDto;

import java.io.IOException;

/**
 * Sends device commands to the firmware via MQTT.
 */
public interface DeviceCommandService {

    /**
     * Sends a command to the specified device (identified by its IoT thing name).
     */
    void sendCommand(String thingName, DeviceCommandDto command) throws IOException;
}
