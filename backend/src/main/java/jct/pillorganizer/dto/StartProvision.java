package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.serde.SerialNumberSerde;
import lombok.Data;

@Introspected
@Data
@Serdeable.Deserializable
public class StartProvision {
    @Serdeable.Deserializable(using = SerialNumberSerde.class)
    private long serialNo;
    private String deviceClass;
}
