package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.*;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.UUID;

@MappedEntity("device_user")
@Getter
@Setter
@Introspected
public class DeviceUser {
    @Id
    private UUID id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private LogicalDevice device;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private User user;

    private boolean primaryUser;

    @Nullable
    private String nickname;

    /** ARN of the SNS subscription linking this user to the device's SNS topic. Null when not subscribed. */
    @Nullable
    private String subscriptionArn;

    @Nullable
    private Boolean notifyTakeNow;

    @Nullable
    private Boolean notifyTaken;

    @Nullable
    private Boolean notifyMissed;

    /** Returns {@code true} when {@code notifyTakeNow} is null (pre-migration rows default to enabled). */
    public boolean effectiveNotifyTakeNow() { return notifyTakeNow == null || notifyTakeNow; }

    /** Returns {@code true} when {@code notifyTaken} is null (pre-migration rows default to enabled). */
    public boolean effectiveNotifyTaken()   { return notifyTaken == null || notifyTaken; }

    /** Returns {@code true} when {@code notifyMissed} is null (pre-migration rows default to enabled). */
    public boolean effectiveNotifyMissed()  { return notifyMissed == null || notifyMissed; }

    @DateCreated
    @JsonIgnore
    private Timestamp createdAt;

    @DateUpdated
    @JsonIgnore
    private Timestamp updatedAt;

}
