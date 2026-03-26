package jct.pillorganizer.tenant.crac;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.service.TenantService;
import jct.pillorganizer.tenant.model.device.LogicalDevice;
import jct.pillorganizer.tenant.projection.UserProfileView;
import jct.pillorganizer.tenant.service.DeviceService;
import jct.pillorganizer.tenant.service.UserService;
import lombok.extern.flogger.Flogger;
import org.crac.Context;
import org.crac.Resource;

import java.util.Optional;

@Flogger
@Singleton
@Requires(env = "lambda")
public class DbPrimer implements OrderedResource {

    @Inject
    DeviceService deviceService;
    @Inject
    UserService userService;

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        try {
            Optional<UserProfileView> profileView = userService.getUserProfile("USER-DOES-NOT-EXIST");
            log.atInfo().log("User profile primed: %s", profileView.toString());
        } catch (Exception ex) {
            // Exception likely: current tenant not defined
        }
        try {
            Optional<LogicalDevice> logicalDevice = deviceService.get("DEVICE-DOES-NOT-EXIST");
            log.atInfo().log("Database primed: %s", logicalDevice.toString());
        } catch (Exception ex) {
            // Ignore result
        }
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
