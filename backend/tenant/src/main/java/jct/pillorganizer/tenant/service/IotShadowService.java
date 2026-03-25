package jct.pillorganizer.tenant.service;

import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;
import jct.pillorganizer.tenant.dto.DeviceScheduleDTO;
import jct.pillorganizer.tenant.dto.ShadowStateDTO;
import jct.pillorganizer.tenant.dto.ShadowStateStateDTO;
import jct.pillorganizer.tenant.exceptions.DeviceAccessException;
import jct.pillorganizer.tenant.model.device.DeviceSchedule;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.iotdataplane.IotDataPlaneClient;
import software.amazon.awssdk.services.iotdataplane.model.IotDataPlaneException;
import software.amazon.awssdk.services.iotdataplane.model.ResourceNotFoundException;
import software.amazon.awssdk.services.iotdataplane.model.UpdateThingShadowRequest;
import software.amazon.awssdk.services.iotdataplane.model.UpdateThingShadowResponse;

import java.io.IOException;

@Flogger
@Singleton
public class IotShadowService {

    public static final String SCHEDULE_SHADOW = "schedule";

    private final ObjectMapper objectMapper;
    private final IotDataPlaneClient iotDataPlaneClient;

    // Micronaut automatically injects the configured AWS SDK v2 client
    public IotShadowService(IotDataPlaneClient iotDataPlaneClient, ObjectMapper objectMapper) {
        this.iotDataPlaneClient = iotDataPlaneClient;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void updateSchedule(LogicalDevice device, DeviceScheduleDTO scheduleDTO) throws IOException {
        if(device.getPhysicalDevice() == null) {
            throw new IllegalStateException("Device has no physical device associated with it");
        } else if(device.getPhysicalDevice().getThingName() == null) {
            throw new IllegalStateException("Device has no thing name associated with it");
        }

        ShadowStateDTO shadowStateDTO = new ShadowStateDTO(
                null,
                null,
                new ShadowStateStateDTO(scheduleDTO, null, null)
        );
        updateDesiredShadow(device.getPhysicalDevice().getThingName(), SCHEDULE_SHADOW, shadowStateDTO);
    }

    @Transactional
    public void test() {

    }

    public void updateDesiredShadow(String thingName, String shadowName, ShadowStateDTO shadowState) throws IOException {
        try {
            SdkBytes payload = SdkBytes.fromUtf8String(objectMapper.writeValueAsString(shadowState));

            UpdateThingShadowRequest request = UpdateThingShadowRequest.builder()
                    .thingName(thingName)
                    .payload(payload)
                    .shadowName(shadowName)
                    .build();

            // Execute the update
            UpdateThingShadowResponse response = iotDataPlaneClient.updateThingShadow(request);
            String acceptedResponseJson = response.payload().asUtf8String();
            log.atInfo().log("Thing %s accepted state update: %s", thingName, acceptedResponseJson);
        } catch(ResourceNotFoundException ex) {
            log.atInfo().withCause(ex).log("Thing name not found: %s", thingName);
            throw new DeviceAccessException("Thing name not found");
        } catch(IotDataPlaneException ex) {
            log.atInfo().withCause(ex).log("AWS IoT Service error updating thing %s shadow %s state: %s",
                    thingName, shadowName, objectMapper.writeValueAsString(shadowState));
            throw new RuntimeException(ex);
        }
    }
}