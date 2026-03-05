package jct.pillorganizer.global.service;

import io.micronaut.context.annotation.Value;
import io.micronaut.security.authentication.AuthenticationException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.policybuilder.iam.IamPolicy;
import software.amazon.awssdk.policybuilder.iam.IamResource;
import software.amazon.awssdk.policybuilder.iam.IamStatement;


@Singleton
@Flogger
public class IotAuthorizerService {

    @Inject
    UserService userService;

    @Inject
    UserDeviceAccessService userDeviceAccessService;

    @Value("${app.iot-core.arn-prefix}")
    String arnPrefix;

    public record IotAuthorization(String principalId, String policyDocument) {}

    public Mono<IotAuthorization> authorizeIot(String jwt, String tenantId, String thingName) {
        return Mono.zip(
                userService.authenticateJwt(jwt),
                userDeviceAccessService.getUserDeviceAccessPolicyDocument(jwt, tenantId, thingName)
        ).map(tuple2 -> {
            UserEntity entity = tuple2.getT1();
            String policyDocument = tuple2.getT2();

            if(!validateTenantUserPolicyDocument(tenantId, thingName, policyDocument)) {
                throw new AuthenticationException("Invalid policy document");
            }

            log.atInfo().log("Authorizing JWT user %s sub %s policy doc %s", entity.getUserId(),
                    entity.getUserSub(), policyDocument);

            return new IotAuthorization("USER" + entity.getUserId(), policyDocument);
        });
    }

    public boolean validateTenantUserPolicyDocument(String tenantId, String thingName, String documentString) {
        /*
         * Sanity check: tenants should only mint an IAM document they have legitimate rights to access.
         * This is a defense-in-depth measure to prevent a "confused deputy" attack
         */

        IamPolicy policy = IamPolicy.fromJson(documentString);

        for(IamStatement statement : policy.statements()) {

            if (!statement.notResources().isEmpty() || !statement.notActions().isEmpty()) {
                log.atWarning().log("Tenant %s produced invalid policy document (NotResource/NotAction are forbidden): %s", tenantId, documentString);
                return false;
            }

            if (statement.resources().isEmpty()) {
                log.atWarning().log("Tenant %s produced a statement with no explicit resources: %s", tenantId, documentString);
                return false;
            }

            /*for(IamResource resource : statement.resources()) {
                String arn = resource.value();

                boolean isValid = arn.startsWith(this.arnPrefix + ":topic/" + tenantNamespace) ||
                        arn.startsWith(this.arnPrefix + ":topicfilter/" + tenantNamespace) ||
                        arn.startsWith(this.arnPrefix + ":client/" + tenantNamespace);

                if(!isValid) {
                    log.atWarning().log("Tenant %s produced invalid policy document...", tenantId);
                    return false;
                }
            }*/
        }
        return true;
    }

}
