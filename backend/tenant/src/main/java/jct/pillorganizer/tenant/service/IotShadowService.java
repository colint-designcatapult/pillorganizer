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
            log.atInfo().log("Thing %s shadow %s accepted state update (responseSize=%d chars)",
                    thingName, shadowName, acceptedResponseJson.length());
        } catch(ResourceNotFoundException ex) {
            log.atWarning().withCause(ex).log("Thing name not found for thing %s shadow %s", thingName, shadowName);
            throw new DeviceAccessException("Thing name not found");
        } catch(IotDataPlaneException ex) {
            log.atSevere().withCause(ex).log(
                    "AWS IoT Service error updating thing %s shadow %s (statusCode=%d, awsErrorCode=%s, requestId=%s)",
                    thingName,
                    shadowName,
                    ex.statusCode(),
                    ex.awsErrorDetails() != null ? ex.awsErrorDetails().errorCode() : null,
                    ex.requestId());
            throw new RuntimeException(ex);
        }
    }
}