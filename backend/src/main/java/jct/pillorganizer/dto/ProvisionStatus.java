package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Data;

@Introspected
@Data
@Serdeable.Serializable
public class ProvisionStatus {

    private final boolean provisioned;
    private final long deviceID;

}
