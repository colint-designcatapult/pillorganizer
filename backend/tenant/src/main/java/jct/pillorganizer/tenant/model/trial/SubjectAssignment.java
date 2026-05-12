package jct.pillorganizer.tenant.model.trial;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Version;
import io.micronaut.serde.annotation.Serdeable;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@MappedEntity("subject_assignment")
@Getter
@Setter
@Introspected
@Serdeable
public class SubjectAssignment {
    @Id
    private UUID id;

    private String serialNo;

    private String subjectId;

    @Version
    private Long version;
}
