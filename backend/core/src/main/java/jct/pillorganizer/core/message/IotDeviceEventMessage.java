package jct.pillorganizer.core.message;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Builder;

@Builder
@Serdeable
public record IotDeviceEventMessage(
        Long timestamp,
        String thingName,
        String tenant,
        @JsonProperty("event_type") String eventType,
        @Nullable @JsonProperty("bin_id") Integer binId,
        @Nullable Integer flags,
        @Nullable @JsonProperty("schedule_id") String scheduleId,
        @Nullable @JsonProperty("epoch_week") Long epochWeek,
        @Nullable @JsonProperty("scheduled_time") Long scheduledTime
) implements BaseMessage {
    @Override
    public String getType() {
        return "deviceEvent";
    }
}
