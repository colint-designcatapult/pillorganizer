package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.DeviceCommandDto;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.iotdataplane.IotDataPlaneClient;
import software.amazon.awssdk.services.iotdataplane.model.PublishRequest;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Production implementation of {@link DeviceCommandService}.
 * Publishes MQTT commands to the device via AWS IoT Data Plane.
 */
@Flogger
@Singleton
@Requires(env = "tenant")
public class IotDeviceCommandService implements DeviceCommandService {

    private static final long MESSAGE_EXPIRY_SECONDS = 900; // 15 minutes

    private final IotDataPlaneClient iotDataPlaneClient;
    private final ObjectMapper objectMapper;

    public IotDeviceCommandService(IotDataPlaneClient iotDataPlaneClient, ObjectMapper objectMapper) {
        this.iotDataPlaneClient = iotDataPlaneClient;
        this.objectMapper = objectMapper;
    }

    @Override
    public void sendCommand(String thingName, DeviceCommandDto command) throws IOException {
        String topic;
        Map<String, Object> payload = new HashMap<>();

        switch (command.type()) {
            case RELOAD -> {
                topic = "healthe/things/" + thingName + "/cmd/reload";
                payload.put("reload", command.reload().name());
            }
            case BIN -> {
                topic = "healthe/things/" + thingName + "/cmd/bin";
                payload.put("bin", command.binId());
                payload.put("type", command.binAction().name());
            }
            default -> throw new IllegalArgumentException("Unknown command type: " + command.type());
        }

        String json = objectMapper.writeValueAsString(payload);
        log.atInfo().log("Sending command to thing %s on topic %s: %s", thingName, topic, json);

        PublishRequest request = PublishRequest.builder()
                .topic(topic)
                .qos(1)
                .payload(SdkBytes.fromUtf8String(json))
                .messageExpiry(MESSAGE_EXPIRY_SECONDS)
                .build();

        iotDataPlaneClient.publish(request);
    }
}
