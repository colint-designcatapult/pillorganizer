package jct.pillorganizer.tenant.model.device;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@MappedEntity("device_event")
@Getter
@Setter
@Introspected
@Serdeable
public class DeviceEvent {

    @Id
    private UUID id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private LogicalDevice logicalDevice;

    /** UTC instant of the event, derived from the MQTT Unix-millisecond timestamp. */
    private Instant timestamp;

    private String eventType;

    @Nullable
    private Integer binId;

    /** Serialized JSON derived from the MQTT {@code flags} field. */
    @Nullable
    private String metadata;

    @Nullable
    private String scheduleId;
}
