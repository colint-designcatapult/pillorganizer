package jct.pillorganizer.tenant.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

@Introspected
@Serdeable.Serializable
public class DeviceUserSettings {
    private boolean notifications;

    public void setNotificationToken(String title) {
        this.notifications = title != null && !title.isBlank();
    }

    @JsonProperty("notifications")
    public boolean setNotificationToken() {
        return notifications;
    }

}
