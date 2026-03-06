package jct.pillorganizer.global.function;

import io.micronaut.function.aws.MicronautRequestHandler;
import jakarta.inject.Inject;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.service.DeviceProvisionService;
import lombok.extern.flogger.Flogger;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Flogger
public class IotProvisioningHook extends MicronautRequestHandler<Map<String, Object>, Map<String, Object>> {

    @Inject
    DeviceProvisionService deviceProvisionService;

    @Override
    public Map<String, Object> execute(Map<String, Object> input) {
        log.atInfo().log("Received Pre-Provisioning Hook request: %s", input);
        try {
            // Extract the parameters sent by the device in its MQTT payload
            Map<String, String> parameters = (Map<String, String>) input.get("parameters");

            if (parameters == null || !parameters.containsKey("SerialNumber") || !parameters.containsKey("ClaimToken")) {
                log.atInfo().log("Provisioning failed: Missing SerialNumber or ClaimToken in parameters");
                return generateDenyResponse();
            }

            String serialNumber = parameters.get("SerialNumber");
            String claimId = parameters.get("ClaimId");
            String claimToken = parameters.get("ClaimToken");

            DeviceEntity device = deviceProvisionService.provisionDevice(serialNumber, claimId, claimToken);

            String thingName = device.getThingName();
            String tenantId = device.getTenantId();
            String deviceId = device.getDeviceId();

            log.atInfo().log("Device %s validated and provisioned for tenant %s. Assigned DeviceId: %s", serialNumber, tenantId, deviceId);
            return generateAllowResponse(tenantId, deviceId, thingName);

        } catch (Exception e) {
            log.atInfo().withCause(e).log("Error processing Pre-Provisioning Hook request");
            return generateDenyResponse();
        }
    }

    /**
     * Generates the successful response expected by AWS IoT Fleet Provisioning.
     */
    private Map<String, Object> generateAllowResponse(String tenantId, String deviceId, String thingName) {
        Map<String, Object> response = new HashMap<>();

        // Tell AWS IoT to proceed with creating the certificate and Thing
        response.put("allowProvisioning", true);

        Map<String, String> parameterOverrides = new HashMap<>();
        parameterOverrides.put("TenantId", tenantId);
        parameterOverrides.put("DeviceId", deviceId);
        parameterOverrides.put("ThingName", thingName);

        response.put("parameterOverrides", parameterOverrides);

        return response;
    }

    /**
     * Generates a deny response to reject the provisioning attempt.
     */
    private Map<String, Object> generateDenyResponse() {
        Map<String, Object> response = new HashMap<>();
        response.put("allowProvisioning", false);
        return response;
    }
}
