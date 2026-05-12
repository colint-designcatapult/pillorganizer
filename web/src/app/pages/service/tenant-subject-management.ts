import { Component, OnInit, DestroyRef, signal, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Subject, switchMap } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { ToastModule } from 'primeng/toast';
import { DialogModule } from 'primeng/dialog';
import { MessageService, ConfirmationService } from 'primeng/api';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { SubjectAssignmentService, SubjectAssignment } from '@/app/services/subject-assignment.service';
import { UserService } from '@/app/services/user.service';

@Component({
    selector: 'app-tenant-subject-management',
    standalone: true,
    imports: [CommonModule, FormsModule, TableModule, ButtonModule, InputTextModule, InputIconModule, IconFieldModule, ToastModule, DialogModule, ConfirmDialogModule],
    providers: [MessageService, ConfirmationService],
    template: `
        <p-toast />
        <p-confirmDialog />
        <div class="card">
            <p-table [value]="assignments()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="serialNo">
                <ng-template #caption>
                    <div class="flex justify-between items-center flex-wrap gap-3">
                        <span class="text-2xl font-semibold">Subject Management — {{ tenantId }}</span>
                        <div class="flex items-center gap-3 ml-auto">
                            <p-iconfield iconPosition="left">
                                <p-inputicon><i class="pi pi-search"></i></p-inputicon>
                                <input pInputText type="text" [(ngModel)]="serialFilterValue"
                                       (ngModelChange)="onFilterChange()"
                                       placeholder="Filter by serial..." />
                            </p-iconfield>
                            <p-iconfield iconPosition="left">
                                <p-inputicon><i class="pi pi-search"></i></p-inputicon>
                                <input pInputText type="text" [(ngModel)]="subjectFilterValue"
                                       (ngModelChange)="onFilterChange()"
                                       placeholder="Filter by subject..." />
                            </p-iconfield>
                            @if (serialFilterValue || subjectFilterValue) {
                                <p-button icon="pi pi-times" [text]="true" severity="secondary" (click)="clearFilters()" />
                            }
                            <p-button label="New Assignment" icon="pi pi-plus" (click)="openNewDialog()" />
                        </div>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Serial Number</th>
                        <th>Subject ID</th>
                        <th style="width:10rem">Actions</th>
                    </tr>
                </ng-template>
                <ng-template #body let-item>
                    <tr>
                        <td><code class="text-sm">{{ item.serialNo }}</code></td>
                        <td><code class="text-sm">{{ item.subjectId }}</code></td>
                        <td>
                            <div class="flex gap-2">
                                <p-button icon="pi pi-pencil" [rounded]="true" [text]="true" severity="info"
                                    (click)="openEditDialog(item)" />
                                <p-button icon="pi pi-trash" [rounded]="true" [text]="true" severity="danger"
                                    (click)="confirmDelete(item)" />
                            </div>
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="3" class="text-center text-muted-color py-6">No subject assignments found.</td></tr>
                </ng-template>
                <ng-template #footer>
                    <tr>
                        <td colspan="3">
                            <div class="flex justify-between items-center">
                                <p-button label="Previous" icon="pi pi-chevron-left" [text]="true"
                                    [disabled]="cursorStack().length === 0 || loading()"
                                    (click)="prevPage()" />
                                <span class="text-muted-color text-sm">Page {{ cursorStack().length + 1 }}</span>
                                <p-button label="Next" icon="pi pi-chevron-right" iconPos="right" [text]="true"
                                    [disabled]="!nextCursor() || loading()"
                                    (click)="nextPage()" />
                            </div>
                        </td>
                    </tr>
                </ng-template>
            </p-table>
        </div>

        <p-dialog [(visible)]="dialogVisible" [header]="editMode ? 'Edit Assignment' : 'New Assignment'"
                  [modal]="true" [style]="{ width: '30rem' }">
            <div class="flex flex-col gap-4 mt-4">
                <div class="flex flex-col gap-2">
                    <label for="serialNo">Serial Number</label>
                    <input pInputText id="serialNo" [(ngModel)]="formSerialNo" [disabled]="editMode" />
                </div>
                <div class="flex flex-col gap-2">
                    <label for="subjectId">Subject ID</label>
                    <input pInputText id="subjectId" [(ngModel)]="formSubjectId" />
                </div>
            </div>
            <ng-template #footer>
                <p-button label="Cancel" [text]="true" severity="secondary" (click)="dialogVisible = false" />
                <p-button [label]="editMode ? 'Update' : 'Create'" icon="pi pi-check"
                    [disabled]="!formSerialNo || !formSubjectId || saving()"
                    (click)="saveAssignment()" />
            </ng-template>
        </p-dialog>
    `
})
export class TenantSubjectManagement implements OnInit {
    assignments = signal<SubjectAssignment[]>([]);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);
    loading = signal(false);
    saving = signal(false);

    tenantId = '';
    apiBase = '';
    serialFilterValue = '';
    subjectFilterValue = '';
    private filterSubject = new Subject<{ serial: string; subject: string }>();
    readonly pageSize = 20;

    dialogVisible = false;
    editMode = false;
    formSerialNo = '';
    formSubjectId = '';

    private subjectAssignmentService = inject(SubjectAssignmentService);
    private userService = inject(UserService);
    private messageService = inject(MessageService);
    private confirmationService = inject(ConfirmationService);
    private route = inject(ActivatedRoute);
    private destroyRef = inject(DestroyRef);

    ngOnInit() {
        this.route.paramMap.pipe(
            switchMap(params => {
                this.tenantId = params.get('tenantId')!;
                this.serialFilterValue = '';
                this.subjectFilterValue = '';
                this.cursorStack.set([]);
                this.assignments.set([]);
                return this.userService.getMe().pipe(
                    map(user => user.tenants?.find(t => t.id === this.tenantId)?.apiBase ?? '')
                );
            }),
            takeUntilDestroyed(this.destroyRef)
        ).subscribe(apiBase => {
            this.apiBase = apiBase;
            this.load(null);
        });

        this.filterSubject.pipe(
            debounceTime(400),
            distinctUntilChanged((a, b) => JSON.stringify(a) === JSON.stringify(b)),
            takeUntilDestroyed(this.destroyRef)
        ).subscribe(() => {
            this.cursorStack.set([]);
            this.load(null);
        });
    }

    onFilterChange() {
        this.filterSubject.next({ serial: this.serialFilterValue, subject: this.subjectFilterValue });
    }
    clearFilters() {
        this.serialFilterValue = '';
        this.subjectFilterValue = '';
        this.filterSubject.next({ serial: '', subject: '' });
    }

    nextPage() {
        const cursor = this.nextCursor();
        if (!cursor) return;
        this.cursorStack.set([...this.cursorStack(), cursor]);
        this.load(cursor);
    }

    prevPage() {
        const stack = this.cursorStack();
        if (stack.length === 0) return;
        const newStack = stack.slice(0, -1);
        const prevCursor = newStack.length === 0 ? null : newStack[newStack.length - 1];
        this.cursorStack.set(newStack);
        this.load(prevCursor);
    }

    openNewDialog() {
        this.editMode = false;
        this.formSerialNo = '';
        this.formSubjectId = '';
        this.dialogVisible = true;
    }

    openEditDialog(item: SubjectAssignment) {
        this.editMode = true;
        this.formSerialNo = item.serialNo;
        this.formSubjectId = item.subjectId;
        this.dialogVisible = true;
    }

    saveAssignment() {
        this.saving.set(true);
        const op = this.editMode
            ? this.subjectAssignmentService.updateAssignment(this.apiBase, this.formSerialNo, this.formSubjectId)
            : this.subjectAssignmentService.createAssignment(this.apiBase, this.formSerialNo, this.formSubjectId);

        op.pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
            next: () => {
                this.messageService.add({
                    severity: 'success',
                    summary: this.editMode ? 'Updated' : 'Created',
                    detail: `Assignment ${this.formSerialNo} → ${this.formSubjectId}`
                });
                this.dialogVisible = false;
                this.saving.set(false);
                this.cursorStack.set([]);
                this.load(null);
            },
            error: (err) => {
                this.saving.set(false);
                const detail = err?.error?.message ?? err?.error?._embedded?.errors?.[0]?.message ?? 'An error occurred';
                this.messageService.add({ severity: 'error', summary: 'Error', detail });
            }
        });
    }

    confirmDelete(item: SubjectAssignment) {
        this.confirmationService.confirm({
            message: `Delete assignment ${item.serialNo} → ${item.subjectId}?`,
            header: 'Confirm Delete',
            icon: 'pi pi-exclamation-triangle',
            acceptButtonStyleClass: 'p-button-danger',
            accept: () => {
                this.subjectAssignmentService.deleteAssignment(this.apiBase, item.serialNo)
                    .pipe(takeUntilDestroyed(this.destroyRef))
                    .subscribe({
                        next: () => {
                            this.messageService.add({ severity: 'success', summary: 'Deleted', detail: `Assignment for ${item.serialNo} removed` });
                            this.cursorStack.set([]);
                            this.load(null);
                        },
                        error: () => {
                            this.messageService.add({ severity: 'error', summary: 'Error', detail: 'Failed to delete assignment' });
                        }
                    });
            }
        });
    }

    private load(cursor: string | null) {
        if (!this.apiBase) return;
        this.loading.set(true);
        this.subjectAssignmentService.listAssignments(
            this.apiBase, cursor, this.pageSize,
            this.serialFilterValue || null, this.subjectFilterValue || null
        ).pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
            next: (page) => {
                this.assignments.set(page.items);
                this.nextCursor.set(page.nextCursor);
                this.loading.set(false);
            },
            error: () => {
                this.loading.set(false);
                this.messageService.add({ severity: 'error', summary: 'Error', detail: 'Failed to load assignments' });
            }
        });
    }
}
