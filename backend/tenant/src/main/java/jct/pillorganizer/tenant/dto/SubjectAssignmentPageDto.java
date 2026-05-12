package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Introspected
@Serdeable
public record SubjectAssignmentPageDto(
        List<SubjectAssignmentDto> items,
        @Nullable String nextCursor
) {}
