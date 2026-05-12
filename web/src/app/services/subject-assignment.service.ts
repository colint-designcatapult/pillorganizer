import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

export interface SubjectAssignment {
    serialNo: string;
    subjectId: string;
}

export interface SubjectAssignmentPage {
    items: SubjectAssignment[];
    nextCursor: string | null;
}

@Injectable({ providedIn: 'root' })
export class SubjectAssignmentService {
    private http = inject(HttpClient);

    listAssignments(apiBase: string, cursor?: string | null, size = 20,
                    serialFilter?: string | null, subjectFilter?: string | null): Observable<SubjectAssignmentPage> {
        const params: Record<string, string | number> = { size };
        if (cursor) params['cursor'] = cursor;
        if (serialFilter) params['serialFilter'] = serialFilter;
        if (subjectFilter) params['subjectFilter'] = subjectFilter;
        return this.http.get<SubjectAssignmentPage>(`${apiBase}/tenant-admin/subjects`, { params });
    }

    createAssignment(apiBase: string, serialNo: string, subjectId: string): Observable<SubjectAssignment> {
        return this.http.post<SubjectAssignment>(`${apiBase}/tenant-admin/subjects`, { serialNo, subjectId });
    }

    updateAssignment(apiBase: string, serialNo: string, newSubjectId: string): Observable<SubjectAssignment> {
        return this.http.put<SubjectAssignment>(
            `${apiBase}/tenant-admin/subjects/${encodeURIComponent(serialNo)}`,
            { serialNo, subjectId: newSubjectId }
        );
    }

    deleteAssignment(apiBase: string, serialNo: string): Observable<void> {
        return this.http.delete<void>(`${apiBase}/tenant-admin/subjects/${encodeURIComponent(serialNo)}`);
    }
}
