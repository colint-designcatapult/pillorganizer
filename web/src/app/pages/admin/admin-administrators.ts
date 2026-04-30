import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { AdminService, AdminCognitoUser } from '@/app/services/admin.service';

type TagSeverity = 'success' | 'info' | 'warn' | 'danger' | 'secondary' | 'contrast';

@Component({
    selector: 'app-admin-administrators',
    standalone: true,
    imports: [CommonModule, ButtonModule, TableModule, TagModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="card">
            <p-table [value]="users()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="sub">
                <ng-template #caption>
                    <span class="text-2xl font-semibold">Administrators</span>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>Email</th>
                        <th>Status</th>
                        <th>Sub</th>
                        <th>Groups</th>
                    </tr>
                </ng-template>
                <ng-template #body let-user>
                    <tr>
                        <td>{{ user.email ?? '—' }}</td>
                        <td>
                            <p-tag [value]="statusLabel(user.status)"
                                   [severity]="statusSeverity(user.status)" />
                        </td>
                        <td><code class="text-xs">{{ user.sub }}</code></td>
                        <td>
                            @for (group of user.groups; track group) {
                                <p-tag [value]="group" severity="secondary" styleClass="mr-1" />
                            }
                            @if (!user.groups || user.groups.length === 0) {
                                <span class="text-muted-color text-sm">—</span>
                            }
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="4" class="text-center text-muted-color py-6">No administrators found.</td></tr>
                </ng-template>
                <ng-template #footer>
                    <tr>
                        <td colspan="4">
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
export class AdminAdministrators implements OnInit {
    users = signal<AdminCognitoUser[]>([]);
    loading = signal(false);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);

    readonly pageSize = 20;

    constructor(private adminService: AdminService) {}

    ngOnInit() {
        this.loadPage(null);
    }

    private loadPage(cursor: string | null) {
        this.loading.set(true);
        this.adminService.listCognitoUsers(cursor, this.pageSize).subscribe({
            next: (data) => {
                this.users.set(data.items);
                this.nextCursor.set(data.nextCursor);
                this.loading.set(false);
            },
            error: () => this.loading.set(false)
        });
    }

    nextPage() {
        const cursor = this.nextCursor();
        if (!cursor) return;
        this.cursorStack.set([...this.cursorStack(), cursor]);
        this.loadPage(cursor);
    }

    prevPage() {
        const stack = this.cursorStack();
        if (stack.length === 0) return;
        const newStack = stack.slice(0, -1);
        const prevCursor = newStack.length === 0 ? null : newStack[newStack.length - 1];
        this.cursorStack.set(newStack);
        this.loadPage(prevCursor);
    }

    statusLabel(status: string): string {
        const map: Record<string, string> = {
            CONFIRMED: 'Active',
            FORCE_CHANGE_PASSWORD: 'Invited',
            UNCONFIRMED: 'Unconfirmed',
            RESET_REQUIRED: 'Reset Required',
            COMPROMISED: 'Compromised',
            UNKNOWN: 'Unknown',
        };
        return map[status] ?? status;
    }

    statusSeverity(status: string): TagSeverity {
        const map: Record<string, TagSeverity> = {
            CONFIRMED: 'success',
            FORCE_CHANGE_PASSWORD: 'info',
            UNCONFIRMED: 'warn',
            RESET_REQUIRED: 'warn',
            COMPROMISED: 'danger',
        };
        return map[status] ?? 'secondary';
    }
}
