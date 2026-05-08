package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;
import software.amazon.awssdk.services.iot.IotClient;
import software.amazon.awssdk.services.iot.model.CertificateStatus;
import software.amazon.awssdk.services.iot.model.ResourceNotFoundException;

import java.util.List;

/**
 * Production implementation of {@link IotThingService}.
 * Deletes IoT Things via the AWS IoT control-plane API.
 * Active in the {@code tenant} environment.
 */
@Flogger
@Singleton
@Requires(env = "tenant")
public class AwsIotThingService implements IotThingService {

    private final IotClient iotClient;

    public AwsIotThingService(IotClient iotClient) {
        this.iotClient = iotClient;
    }

    @Override
    public void revokeAllCerts(String thingName) {
        try {
            log.atInfo().log("Revoking all certificates for IoT Thing: %s", thingName);
            List<String> principals = iotClient.listThingPrincipals(b -> b.thingName(thingName)).principals();
            for (String principal : principals) {
                try {
                    iotClient.detachThingPrincipal(b -> b.thingName(thingName).principal(principal));
                    log.atInfo().log("Detached principal %s from thing %s", principal, thingName);

                    String certId = principal.substring(principal.lastIndexOf('/') + 1);
                    iotClient.updateCertificate(b -> b.certificateId(certId).newStatus(CertificateStatus.REVOKED));
                    log.atInfo().log("Revoked certificate %s", certId);
                } catch (ResourceNotFoundException ex) {
                    log.atInfo().log("Principal %s not found", principal);
                }
            }
        } catch (ResourceNotFoundException ex) {
            log.atInfo().log("Thing %s not found", thingName);
        }
    }

    @Override
    public void deleteThing(String thingName) {
        log.atInfo().log("Deleting IoT Thing: %s", thingName);
        iotClient.deleteThing(b -> b.thingName(thingName));
    }
}
