package jct.pillorganizer.global;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.repo.DeviceRepo;
import jct.pillorganizer.global.service.UserDeviceAccessService;
import org.crac.Context;
import org.crac.Resource;
import software.amazon.awssdk.services.iot.IotClient;

@Singleton
@Requires(notEnv = "test")
public class CracPrimer implements OrderedResource {
    private final DeviceRepo deviceRepo;
    private final UserDeviceAccessService userDeviceAccessService;
    private final IotClient iotClient;

    @Inject
    public CracPrimer(DeviceRepo deviceRepo, UserDeviceAccessService userDeviceAccessService,
                      IotClient iotClient) {
        this.deviceRepo = deviceRepo;
        this.userDeviceAccessService = userDeviceAccessService;
        this.iotClient = iotClient;
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        deviceRepo.findBySerialNumber("test");
        try {
            userDeviceAccessService.getUserDeviceAccess();
        } catch (Exception ex) {
            // Swallow exception: just need to prime the client, doesn't need to succeed
        }
        try {
            iotClient.describeEndpoint(r -> r.endpointType("iot:Data-ATS"));
        } catch (Exception ex) {}
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }

    @Override
    public int getOrder() {
        // Move down the order so HTTP server is initialized
        return 1;
    }
}
