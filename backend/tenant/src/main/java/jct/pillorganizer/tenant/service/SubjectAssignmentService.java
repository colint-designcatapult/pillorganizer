package jct.pillorganizer.tenant.service;

import io.micronaut.core.annotation.Nullable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.trial.SubjectAssignment;
import jct.pillorganizer.tenant.repo.SubjectAssignmentRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Singleton
public class SubjectAssignmentService {

    @Inject
    SubjectAssignmentRepository subjectAssignmentRepository;

    public SubjectAssignment createAssignment(String serialNo, String subjectId) {
        SubjectAssignment assignment = new SubjectAssignment();
        assignment.setId(UUID.randomUUID());
        assignment.setSerialNo(serialNo);
        assignment.setSubjectId(subjectId);
        return subjectAssignmentRepository.save(assignment);
    }

    public Optional<SubjectAssignment> getBySerialNo(String serialNo) {
        return subjectAssignmentRepository.findBySerialNo(serialNo);
    }

    public Optional<SubjectAssignment> getBySubjectId(String subjectId) {
        return subjectAssignmentRepository.findBySubjectId(subjectId);
    }

    public SubjectAssignment updateAssignment(SubjectAssignment existing, String newSubjectId) {
        existing.setSubjectId(newSubjectId);
        return subjectAssignmentRepository.update(existing);
    }

    public void deleteAssignment(SubjectAssignment existing) {
        subjectAssignmentRepository.delete(existing);
    }

    public List<SubjectAssignment> listAssignments(@Nullable String serialFilter,
                                                   @Nullable String subjectFilter,
                                                   @Nullable String cursorSerial,
                                                   int size) {
        return subjectAssignmentRepository.listAssignments(serialFilter, subjectFilter, cursorSerial, size);
    }
}
