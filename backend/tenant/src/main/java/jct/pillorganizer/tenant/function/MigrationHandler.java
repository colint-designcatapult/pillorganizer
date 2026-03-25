package jct.pillorganizer.tenant.function;

import io.micronaut.function.aws.MicronautRequestHandler;
import jakarta.inject.Inject;
import lombok.extern.flogger.Flogger;
import org.flywaydb.core.Flyway;

import java.util.Map;

@Flogger
public class MigrationHandler extends MicronautRequestHandler<Map<String, Object>, String> {

    @Inject
    Flyway flyway;

    public MigrationHandler() {
        // Empty ctor for lambda
    }

    @Inject
    public MigrationHandler(Flyway flyway) {

    }

    @Override
    public String execute(Map<String, Object> input) {
        if(flyway != null && flyway.info() != null && flyway.info().current() != null) {
            return "{\"status\":\"success\", \"ver\":\"" + flyway.info().current().getVersion() + "\"}";
        }
        log.atWarning().log("Flyway or info is null");
        return "{\"status\":\"failure\"}";
    }
}
