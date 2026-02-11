package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.serde.SerialNumberSerde;
import lombok.Data;

@Introspected
@Data
@Serdeable.Deserializable
@Serdeable.Serializable
public class VerifyProvision {
    @Serdeable.Deserializable(using = SerialNumberSerde.class)
    @Serdeable.Serializable(using = SerialNumberSerde.class)
    private long serialNo;
    private String ssid;
}
