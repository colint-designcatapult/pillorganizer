package jct.pillorganizer.tenant.api.dashboard;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.*;
import io.micronaut.http.exceptions.HttpStatusException;
import io.micronaut.security.annotation.Secured;
import jakarta.inject.Inject;
import jct.pillorganizer.core.auth.AppSecurityRule;
import jct.pillorganizer.tenant.dto.SubjectAssignmentDto;
import jct.pillorganizer.tenant.dto.SubjectAssignmentPageDto;
import jct.pillorganizer.tenant.model.trial.SubjectAssignment;
import jct.pillorganizer.tenant.service.SubjectAssignmentService;

import java.util.List;

@Controller("/tenant-admin/subjects")
@Secured(AppSecurityRule.IS_TENANT_ADMIN)
public class TenantSubjectController {

    @Inject
    SubjectAssignmentService subjectAssignmentService;

    @Post
    public HttpResponse<SubjectAssignmentDto> createAssignment(@Body SubjectAssignmentDto body) {
        try {
            SubjectAssignment created = subjectAssignmentService.createAssignment(
                    body.serialNo(), body.subjectId());
            return HttpResponse.created(toDto(created));
        } catch (Exception e) {
            if (isConstraintViolation(e)) {
                throw new HttpStatusException(HttpStatus.CONFLICT,
                        "Assignment conflict: serial or subject already assigned");
            }
            throw e;
        }
    }

    @Get
    public SubjectAssignmentPageDto listAssignments(
            @QueryValue(defaultValue = "20") int size,
            @Nullable @QueryValue String cursor,
            @Nullable @QueryValue String serialFilter,
            @Nullable @QueryValue String subjectFilter) {

        List<SubjectAssignment> results = subjectAssignmentService.listAssignments(
                serialFilter, subjectFilter, cursor, size + 1);

        String nextCursor = null;
        List<SubjectAssignment> page = results;
        if (results.size() > size) {
            page = results.subList(0, size);
            nextCursor = page.get(page.size() - 1).getSerialNo();
        }

        List<SubjectAssignmentDto> items = page.stream().map(this::toDto).toList();
        return new SubjectAssignmentPageDto(items, nextCursor);
    }

    @Put("/{serialNo}")
    public HttpResponse<SubjectAssignmentDto> updateAssignment(
            @PathVariable String serialNo,
            @Body SubjectAssignmentDto body) {
        SubjectAssignment existing = subjectAssignmentService.getBySerialNo(serialNo)
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND,
                        "No assignment found for serial: " + serialNo));
        try {
            SubjectAssignment updated = subjectAssignmentService.updateAssignment(
                    existing, body.subjectId());
            return HttpResponse.ok(toDto(updated));
        } catch (Exception e) {
            if (isConstraintViolation(e)) {
                throw new HttpStatusException(HttpStatus.CONFLICT,
                        "Subject " + body.subjectId() + " is already assigned to another device");
            }
            throw e;
        }
    }

    @Delete("/{serialNo}")
    public HttpResponse<Void> deleteAssignment(@PathVariable String serialNo) {
        SubjectAssignment existing = subjectAssignmentService.getBySerialNo(serialNo)
                .orElseThrow(() -> new HttpStatusException(HttpStatus.NOT_FOUND,
                        "No assignment found for serial: " + serialNo));
        subjectAssignmentService.deleteAssignment(existing);
        return HttpResponse.noContent();
    }

    private SubjectAssignmentDto toDto(SubjectAssignment sa) {
        return new SubjectAssignmentDto(sa.getSerialNo(), sa.getSubjectId());
    }

    private boolean isConstraintViolation(Exception e) {
        Throwable cause = e;
        while (cause != null) {
            String name = cause.getClass().getName();
            if (name.contains("ConstraintViolation") || name.contains("DuplicateKey")
                    || name.contains("PSQLException") && cause.getMessage() != null
                    && cause.getMessage().contains("duplicate key")) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }
}
