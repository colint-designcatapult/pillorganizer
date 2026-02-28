package jct.pillorganizer.core;

import io.micronaut.context.annotation.EachProperty;
import io.micronaut.context.annotation.Parameter;
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

    public TenantDetails(@Parameter String name) {
        this.id = name;
    }
}
