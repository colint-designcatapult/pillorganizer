import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { AdminService, AdminUserSummary } from '@/app/services/admin.service';

@Component({
    selector: 'app-admin-users',
    standalone: true,
    imports: [CommonModule, FormsModule, TableModule, ButtonModule, InputTextModule, InputIconModule, IconFieldModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="card">
            <p-table [value]="users()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="userId">
                <ng-template #caption>
                    <div class="flex justify-between items-center flex-wrap gap-3">
                        <span class="text-2xl font-semibold">Users</span>
                        <div class="flex items-center gap-3 ml-auto">
                            <p-iconfield iconPosition="left">
                                <p-inputicon><i class="pi pi-search"></i></p-inputicon>
                                <input pInputText type="text" [(ngModel)]="userIdFilterValue"
                                       (ngModelChange)="onFilterChange($event)"
                                       placeholder="Filter by user ID..." />
                            </p-iconfield>
                            @if (userIdFilterValue) {
                                <p-button icon="pi pi-times" [text]="true" severity="secondary" (click)="clearFilter()" />
                            }
                        </div>
                    </div>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>User ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Created</th>
                        <th style="width:4rem"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-user>
                    <tr class="cursor-pointer" (click)="openUser(user)">
                        <td><code class="text-sm">{{ user.userId }}</code></td>
                        <td>{{ user.userName ?? '—' }}</td>
                        <td>{{ user.email }}</td>
                        <td>{{ user.createdAt | date:'short' }}</td>
                        <td>
                            <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true" severity="secondary"
                                (click)="openUser(user); $event.stopPropagation()" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="5" class="text-center text-muted-color py-6">No users found.</td></tr>
                </ng-template>
                <ng-template #footer>
                    <tr>
                        <td colspan="5">
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
    `
})
export class AdminUsers implements OnInit {
    users = signal<AdminUserSummary[]>([]);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);
    loading = signal(false);

    userIdFilterValue = '';
    private filterSubject = new Subject<string>();

    readonly pageSize = 20;

    constructor(private adminService: AdminService, private router: Router) {}

    ngOnInit() {
        this.load(null);
        this.filterSubject.pipe(debounceTime(400), distinctUntilChanged()).subscribe(() => {
            this.cursorStack.set([]);
            this.load(null);
        });
    }

    onFilterChange(value: string) {
        this.filterSubject.next(value);
    }

    clearFilter() {
        this.userIdFilterValue = '';
        this.filterSubject.next('');
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

    private load(cursor: string | null) {
        this.loading.set(true);
        this.adminService.listUsers(cursor, this.pageSize, this.userIdFilterValue || null).subscribe({
            next: (data) => { this.users.set(data.items); this.nextCursor.set(data.nextCursor); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    openUser(user: AdminUserSummary) {
        this.router.navigate(['/admin/users', user.userId]);
    }
}
