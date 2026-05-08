package jct.pillorganizer.core;

import io.micronaut.context.annotation.EachProperty;
import io.micronaut.context.annotation.Parameter;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;

@EachProperty("app.tenant.list")
@Data
@AllArgsConstructor
@Serdeable.Serializable
public class TenantDetails {

    private String id;
    private boolean active;
    private String hostname;
    private String apiBase;
    @Nullable private String name;
    @Nullable private String defaultSchedule;

    public TenantDetails(@Parameter String name) {
        this.id = name;
    }

    public static final TenantDetails TEST_TENANT = new TenantDetails("test", true,
            "test-does-not-exist.domain", "https://test-does-not-exist.domain", "Test Tenant", null);
}
