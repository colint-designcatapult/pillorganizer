package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.policybuilder.iam.*;

@Singleton
@Flogger
public class DeviceIotService {

    @Value("${app.iot-core.arn-prefix}")
    String arnPrefix;

    public String generateDeviceUserAccessPolicyDocument(DeviceUser deviceUser) {
        String thingName = deviceUser.getDevice().getPhysicalDevice().getThingName();

        IamPolicy policy = IamPolicy.builder()
                .addStatement(b -> b
                        .effect(IamEffect.ALLOW)
                        .addAction("iot:Connect")
                        .addResource(arnPrefix + ":client/" + thingName + "/user/" + deviceUser.getUser().getId())
                )
                .addStatement(b -> b
                        .effect(IamEffect.ALLOW)
                        .addAction("iot:Receive")
                        .addResource(arnPrefix + ":topic/healthe/things/" + thingName + "/*")
                        .addResource(arnPrefix + ":topic/$aws/things/" + thingName + "/shadow/*")
                )
                .addStatement(b -> b
                        .effect(IamEffect.ALLOW)
                        .addAction("iot:Subscribe")
                        .addResource(arnPrefix + ":topicfilter/healthe/things/" + thingName + "/*")
                        .addResource(arnPrefix + ":topicfilter/$aws/things/" + thingName + "/shadow/*")
                )
                .build();

        return policy.toJson(IamPolicyWriter.builder()
                .prettyPrint(false)
                .build());
    }

}
