package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import io.micronaut.security.authentication.AuthenticationException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.exception.DeviceAccessException;
import jct.pillorganizer.global.model.DeviceEntity;
import jct.pillorganizer.global.model.UserEntity;
import jct.pillorganizer.global.repo.DeviceRepo;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.policybuilder.iam.*;

import java.util.List;


@Singleton
@Flogger
public class IotAuthorizerService {

    @Inject
    UserService userService;

    @Inject
    UserDeviceAccessService userDeviceAccessService;

    @Inject
    DeviceService deviceService;

    @Value("${app.iot-core.arn-prefix}")
    String arnPrefix;

    public record IotAuthorization(String principalId, List<String> policyDocument) {}

    public Mono<IotAuthorization> authorizeIot(String jwt, String tenantId, String deviceId) {
        DeviceEntity deviceEntity = deviceService.getDevice(deviceId)
                .orElseThrow(() -> new DeviceAccessException("Invalid device ID"));

        // Sanity check: tenant must match the tenant on record
        if(!tenantId.equals(deviceEntity.getTenantId())) {
            log.atWarning().log("Tenant ID mismatch (got %s expected %s)", tenantId, deviceEntity.getTenantId());
            throw new DeviceAccessException("Invalid tenant ID");
        }

        return Mono.zip(
                userService.authenticateJwt(jwt),
                userDeviceAccessService.getUserDeviceAccessPolicyDocument(jwt, tenantId, deviceId)
        ).map(tuple2 -> {
            UserEntity userEntity = tuple2.getT1();
            String policyDocument = tuple2.getT2();

            log.atInfo().log("Authorizing JWT user %s sub %s policy doc %s", userEntity.getUserId(),
                    userEntity.getUserSub(), policyDocument);

            return new IotAuthorization("USER" + userEntity.getUserId(),
                    List.of(policyDocument, generateTenantIsolationPolicy(tenantId),
                            generateDevicePolicy(deviceEntity, userEntity.getUserId())));
        });
    }

    public String generateTenantIsolationPolicy(String tenantId) {
        // Broad default-deny policy based on tenant ID.
        // Thing names start with the tenant.
        IamPolicy policy = IamPolicy.builder()
                .addStatement(b -> b
                        .effect(IamEffect.DENY)
                        .addAction("iot:*")
                        .addNotResource(arnPrefix + ":client/" + tenantId + "-*")
                        .addNotResource(arnPrefix + ":topic/healthe/things/" + tenantId + "-*")
                        .addNotResource(arnPrefix + ":topic/$aws/things/" + tenantId + "-*")
                        .addNotResource(arnPrefix + ":topicfilter/healthe/things/" + tenantId + "-*")
                        .addNotResource(arnPrefix + ":topicfilter/$aws/things/" + tenantId + "-*")
                )
                .addStatement(b -> b
                        .effect(IamEffect.DENY)
                        .addNotAction("iot:Connect")
                        .addNotAction("iot:Publish")
                        .addNotAction("iot:Receive")
                        .addNotAction("iot:Subscribe")
                        .addResource(arnPrefix + ":client/" + tenantId + "-*")
                        .addResource(arnPrefix + ":topic/healthe/things/" + tenantId + "-*")
                        .addResource(arnPrefix + ":topic/$aws/things/" + tenantId + "-*")
                        .addResource(arnPrefix + ":topicfilter/healthe/things/" + tenantId + "-*")
                        .addResource(arnPrefix + ":topicfilter/$aws/things/" + tenantId + "-*")
                )
                .build();

        return policy.toJson(IamPolicyWriter.builder()
                .prettyPrint(false)
                .build());
    }

    public String generateDevicePolicy(DeviceEntity entity, String userId) {
        // Narrow default-deny policy specifically targeting a specific device
        // Ensures a tenant can't mint a policy document for anything other than what it should be able to
        IamPolicy policy = IamPolicy.builder()
                .addStatement(b -> b
                        .effect(IamEffect.DENY)
                        .addAction("iot:*")
                        .addNotResource(arnPrefix + ":client/" + entity.getThingName() + "/user/" + userId)
                        .addNotResource(arnPrefix + ":topic/healthe/things/" + entity.getThingName() + "/*")
                        .addNotResource(arnPrefix + ":topic/$aws/things/" + entity.getThingName() + "/*")
                        .addNotResource(arnPrefix + ":topicfilter/healthe/things/" + entity.getThingName() + "/*")
                        .addNotResource(arnPrefix + ":topicfilter/$aws/things/" + entity.getThingName() + "/*")
                )
                .addStatement(b -> b
                        .effect(IamEffect.DENY)
                        .addNotAction("iot:Connect")
                        .addNotAction("iot:Publish")
                        .addNotAction("iot:Receive")
                        .addNotAction("iot:Subscribe")
                        .addResource(arnPrefix + ":client/" + entity.getThingName() + "/user/" + userId)
                        .addResource(arnPrefix + ":topic/healthe/things/" + entity.getThingName() + "/*")
                        .addResource(arnPrefix + ":topic/$aws/things/" + entity.getThingName() + "/*")
                        .addResource(arnPrefix + ":topicfilter/healthe/things/" + entity.getThingName() + "/*")
                        .addResource(arnPrefix + ":topicfilter/$aws/things/" + entity.getThingName() + "/*")
                )
                .build();

        return policy.toJson(IamPolicyWriter.builder()
                .prettyPrint(false)
                .build());
    }

}
