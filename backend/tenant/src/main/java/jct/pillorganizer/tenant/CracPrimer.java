package jct.pillorganizer.tenant;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.tenant.api.app.AppUserController;
import jct.pillorganizer.tenant.api.internal.InternalUserController;
import jct.pillorganizer.tenant.service.DeviceUserService;
import org.crac.Context;
import org.crac.Resource;

import java.security.Principal;

@Singleton
@Requires(notEnv = "test")
public class CracPrimer implements OrderedResource {
    private final DeviceUserService deviceUserService;

    @Inject
    public CracPrimer(DeviceUserService deviceUserService) {
        this.deviceUserService = deviceUserService;
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        TenantDetails details = new TenantDetails("primer");
        details.setId("primer");
        details.setActive(false);
        details.setHostname("primer-host");
        this.deviceUserService.getDeviceAccess(0, details);
    }

    @Override
    public int getOrder() {
        return 1;
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
