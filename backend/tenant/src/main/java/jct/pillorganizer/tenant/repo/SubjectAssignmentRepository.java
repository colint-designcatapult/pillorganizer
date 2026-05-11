package jct.pillorganizer.tenant.repo;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.model.trial.SubjectAssignment;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface SubjectAssignmentRepository extends CrudRepository<SubjectAssignment, UUID> {

    Optional<SubjectAssignment> findBySerialNo(String serialNo);

    Optional<SubjectAssignment> findBySubjectId(String subjectId);

    @Query("""
        SELECT sa.id, sa.serial_no, sa.subject_id, sa.version
        FROM subject_assignment sa
        WHERE (CAST(:serialFilter AS TEXT) IS NULL OR sa.serial_no ILIKE '%' || :serialFilter || '%')
          AND (CAST(:subjectFilter AS TEXT) IS NULL OR sa.subject_id ILIKE '%' || :subjectFilter || '%')
          AND (CAST(:cursorSerial AS TEXT) IS NULL OR sa.serial_no > :cursorSerial)
        ORDER BY sa.serial_no
        LIMIT :size
    """)
    List<SubjectAssignment> listAssignments(
            @Nullable String serialFilter,
            @Nullable String subjectFilter,
            @Nullable String cursorSerial,
            int size);
}
