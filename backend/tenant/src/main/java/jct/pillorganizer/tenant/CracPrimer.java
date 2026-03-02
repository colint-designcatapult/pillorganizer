package jct.pillorganizer.tenant;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.tenant.service.UserService;
import org.crac.Context;
import org.crac.Resource;

@Singleton
@Requires(notEnv = "test")
public class CracPrimer implements OrderedResource {
    private final UserService userService;

    @Inject
    public CracPrimer(UserService userService) {
        this.userService = userService;
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        TenantDetails details = new TenantDetails("primer");
        details.setId("primer");
        details.setActive(false);
        details.setHostname("primer-host");
        this.userService.getUserProfile("fake_user");
    }

    @Override
    public int getOrder() {
        return 1;
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
