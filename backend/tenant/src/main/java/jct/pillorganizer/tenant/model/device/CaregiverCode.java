package jct.pillorganizer.tenant.model.device;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.micronaut.core.annotation.Introspected;
import io.micronaut.data.annotation.*;
import jct.pillorganizer.tenant.model.user.User;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;
import java.util.UUID;

@MappedEntity("caregiver_code")
@Getter
@Setter
@Introspected
public class CaregiverCode {

    @Id
    private UUID id;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    private LogicalDevice device;

    @Relation(value = Relation.Kind.MANY_TO_ONE)
    @MappedProperty("patient_id")
    private User patient;

    private String nickname;

    private int code;

    private Timestamp expiresAt;

    private boolean deleted;

    @DateCreated
    @JsonIgnore
    private Timestamp createdAt;
}
