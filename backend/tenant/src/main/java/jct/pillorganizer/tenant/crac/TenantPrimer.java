package jct.pillorganizer.tenant.crac;

import io.micronaut.context.annotation.Requires;
import io.micronaut.crac.OrderedResource;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.service.TenantService;
import lombok.extern.flogger.Flogger;
import org.crac.Context;
import org.crac.Resource;

@Flogger
@Singleton
@Requires(env = "lambda")
public class TenantPrimer implements OrderedResource {
    @Inject
    TenantService tenantService;

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        TenantDetails details = tenantService.getTenantDetails("public").get();
        log.atInfo().log("Primed tenant details: %s", details.toString());
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {

    }
}
