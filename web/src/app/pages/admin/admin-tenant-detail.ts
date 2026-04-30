import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import {
    AdminService,
    AdminTenantDetail as AdminTenantDetailDto,
    AdminTenantDeviceRow,
    AdminCognitoUser
} from '@/app/services/admin.service';

type TagSeverity = 'success' | 'info' | 'warn' | 'danger' | 'secondary' | 'contrast';

@Component({
    selector: 'app-admin-tenant-detail',
    standalone: true,
    imports: [CommonModule, FormsModule, ButtonModule, InputTextModule, InputIconModule, IconFieldModule, TableModule, TagModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="flex flex-col gap-4">
            <!-- Back -->
            <div>
                <p-button label="Back to Tenants" icon="pi pi-arrow-left" [text]="true" severity="secondary"
                    (click)="goBack()" />
            </div>

            @if (loadingTenant()) {
                <div class="card flex justify-center py-10">
                    <i class="pi pi-spin pi-spinner text-4xl text-muted-color"></i>
                </div>
            } @else if (tenant()) {
                <!-- Tenant info card -->
                <div class="card">
                    <h2 class="text-2xl font-semibold mb-4">
                        <i class="pi pi-building mr-2"></i>{{ tenant()!.name }}
                    </h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Tenant ID</span>
                            <code class="text-sm">{{ tenant()!.id }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Hostname</span>
                            <code class="text-sm">{{ tenant()!.hostname }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Status</span>
                            <p-tag [value]="tenant()!.active ? 'Active' : 'Inactive'"
                                   [severity]="tenant()!.active ? 'success' : 'danger'" />
                        </div>
                    </div>
                </div>

                <!-- Devices + Mappings merged table -->
                <div class="card">
                    <p-table [value]="rows()" [loading]="loadingDevices()" [rowHover]="true" [showGridlines]="true" dataKey="serialNumber">
                        <ng-template #caption>
                            <div class="flex justify-between items-center flex-wrap gap-3">
                                <span class="text-xl font-semibold">Devices</span>
                                <div class="flex items-center gap-3 ml-auto">
                                    <p-iconfield iconPosition="left">
                                        <p-inputicon><i class="pi pi-search"></i></p-inputicon>
                                        <input pInputText type="text" [(ngModel)]="snFilterValue"
                                               (ngModelChange)="onFilterChange($event)"
                                               placeholder="Filter by serial number..." />
                                    </p-iconfield>
                                    @if (snFilterValue) {
                                        <p-button icon="pi pi-times" [text]="true" severity="secondary" (click)="clearFilter()" />
                                    }
                                </div>
                            </div>
                        </ng-template>
                        <ng-template #header>
                            <tr>
                                <th>Serial Number</th>
                                <th>Device ID</th>
                                <th>Thing Name</th>
                                <th>Claim ID</th>
                                <th>Mapped At</th>
                                <th>Device Created</th>
                                <th style="width:4rem"></th>
                            </tr>
                        </ng-template>
                        <ng-template #body let-row>
                            <tr class="cursor-pointer" (click)="viewDevice(row.serialNumber)">
                                <td><code class="text-xs">{{ row.serialNumber }}</code></td>
                                <td><code class="text-xs">{{ row.deviceId ?? '—' }}</code></td>
                                <td>{{ row.thingName ?? '—' }}</td>
                                <td><code class="text-xs">{{ row.claimId ?? '—' }}</code></td>
                                <td>{{ row.mappingCreatedAt | date:'short' }}</td>
                                <td>{{ row.deviceCreatedAt | date:'short' }}</td>
                                <td>
                                    <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true" severity="secondary"
                                        (click)="viewDevice(row.serialNumber); $event.stopPropagation()" />
                                </td>
                            </tr>
                        </ng-template>
                        <ng-template #emptymessage>
                            <tr><td colspan="7" class="text-center text-muted-color py-6">No devices found for this tenant.</td></tr>
                        </ng-template>
                        <ng-template #footer>
                            <tr>
                                <td colspan="7">
                                    <div class="flex justify-between items-center">
                                        <p-button label="Previous" icon="pi pi-chevron-left" [text]="true"
                                            [disabled]="cursorStack().length === 0 || loadingDevices()"
                                            (click)="prevPage()" />
                                        <span class="text-muted-color text-sm">Page {{ cursorStack().length + 1 }}</span>
                                        <p-button label="Next" icon="pi pi-chevron-right" iconPos="right" [text]="true"
                                            [disabled]="!nextCursor() || loadingDevices()"
                                            (click)="nextPage()" />
                                    </div>
                                </td>
                            </tr>
                        </ng-template>
                    </p-table>

                    <!-- Assign device form -->
                    <div class="mt-6 pt-4 border-t border-surface-border">
                        <h4 class="font-medium mb-3">
                            <i class="pi pi-plus-circle mr-2"></i>Assign Device to Tenant
                        </h4>
                        <div class="flex items-center gap-3">
                            <input pInputText [(ngModel)]="assignSerialNumber"
                                   placeholder="Enter serial number..."
                                   class="flex-1 max-w-xs"
                                   [disabled]="assigning()" />
                            <p-button label="Assign" icon="pi pi-check"
                                      [loading]="assigning()"
                                      [disabled]="!assignSerialNumber.trim()"
                                      (click)="assignDevice()" />
                        </div>
                    </div>
                </div>

                <!-- Tenant Admins table -->
                <div class="card">
                    <p-table [value]="tenantAdmins()" [loading]="loadingAdmins()" [rowHover]="true" [showGridlines]="true" dataKey="sub">
                        <ng-template #caption>
                            <span class="text-xl font-semibold">Tenant Administrators</span>
                        </ng-template>
                        <ng-template #header>
                            <tr>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Sub</th>
                            </tr>
                        </ng-template>
                        <ng-template #body let-admin>
                            <tr>
                                <td>{{ admin.email ?? '—' }}</td>
                                <td>
                                    <p-tag [value]="adminStatusLabel(admin.status)"
                                           [severity]="adminStatusSeverity(admin.status)" />
                                </td>
                                <td><code class="text-xs">{{ admin.sub }}</code></td>
                            </tr>
                        </ng-template>
                        <ng-template #emptymessage>
                            <tr><td colspan="3" class="text-center text-muted-color py-6">No tenant administrators found.</td></tr>
                        </ng-template>
                        <ng-template #footer>
                            <tr>
                                <td colspan="3">
                                    <div class="flex justify-between items-center">
                                        <p-button label="Previous" icon="pi pi-chevron-left" [text]="true"
                                            [disabled]="adminCursorStack().length === 0 || loadingAdmins()"
                                            (click)="prevAdminPage()" />
                                        <span class="text-muted-color text-sm">Page {{ adminCursorStack().length + 1 }}</span>
                                        <p-button label="Next" icon="pi pi-chevron-right" iconPos="right" [text]="true"
                                            [disabled]="!adminNextCursor() || loadingAdmins()"
                                            (click)="nextAdminPage()" />
                                    </div>
                                </td>
                            </tr>
                        </ng-template>
                    </p-table>
                </div>
            } @else {
                <div class="card">
                    <p class="text-muted-color">Tenant not found.</p>
                </div>
            }
        </div>
    `
})
export class AdminTenantDetail implements OnInit {
    tenant = signal<AdminTenantDetailDto | null>(null);
    rows = signal<AdminTenantDeviceRow[]>([]);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);
    loadingTenant = signal(false);
    loadingDevices = signal(false);
    assigning = signal(false);

    tenantAdmins = signal<AdminCognitoUser[]>([]);
    loadingAdmins = signal(false);
    adminNextCursor = signal<string | null>(null);
    adminCursorStack = signal<(string | null)[]>([]);

    snFilterValue = '';
    assignSerialNumber = '';

    private filterSubject = new Subject<string>();
    private tenantId = '';

    readonly pageSize = 20;

    constructor(
        private route: ActivatedRoute,
        private router: Router,
        private adminService: AdminService,
        private messageService: MessageService
    ) {}

    ngOnInit() {
        this.tenantId = this.route.snapshot.paramMap.get('tenantId')!;

        this.loadingTenant.set(true);
        this.adminService.getTenant(this.tenantId).subscribe({
            next: (data) => { this.tenant.set(data); this.loadingTenant.set(false); },
            error: () => this.loadingTenant.set(false)
        });

        this.loadDevices(null);
        this.loadAdmins(null);

        this.filterSubject.pipe(debounceTime(400), distinctUntilChanged()).subscribe(() => {
            this.cursorStack.set([]);
            this.loadDevices(null);
        });
    }

    private loadDevices(cursor: string | null) {
        this.loadingDevices.set(true);
        this.adminService.getTenantDevices(this.tenantId, cursor, this.pageSize, this.snFilterValue || null).subscribe({
            next: (data) => {
                this.rows.set(data.items);
                this.nextCursor.set(data.nextCursor);
                this.loadingDevices.set(false);
            },
            error: () => this.loadingDevices.set(false)
        });
    }

    private loadAdmins(cursor: string | null) {
        this.loadingAdmins.set(true);
        const groupName = `admin-tenant-${this.tenantId}`;
        this.adminService.listGroupUsers(groupName, cursor, this.pageSize).subscribe({
            next: (data) => {
                this.tenantAdmins.set(data.items);
                this.adminNextCursor.set(data.nextCursor);
                this.loadingAdmins.set(false);
            },
            error: () => this.loadingAdmins.set(false)
        });
    }

    onFilterChange(value: string) {
        this.filterSubject.next(value);
    }

    clearFilter() {
        this.snFilterValue = '';
        this.filterSubject.next('');
    }

    nextPage() {
        const cursor = this.nextCursor();
        if (!cursor) return;
        this.cursorStack.set([...this.cursorStack(), cursor]);
        this.loadDevices(cursor);
    }

    prevPage() {
        const stack = this.cursorStack();
        if (stack.length === 0) return;
        const newStack = stack.slice(0, -1);
        const prevCursor = newStack.length === 0 ? null : newStack[newStack.length - 1];
        this.cursorStack.set(newStack);
        this.loadDevices(prevCursor);
    }

    nextAdminPage() {
        const cursor = this.adminNextCursor();
        if (!cursor) return;
        this.adminCursorStack.set([...this.adminCursorStack(), cursor]);
        this.loadAdmins(cursor);
    }

    prevAdminPage() {
        const stack = this.adminCursorStack();
        if (stack.length === 0) return;
        const newStack = stack.slice(0, -1);
        const prevCursor = newStack.length === 0 ? null : newStack[newStack.length - 1];
        this.adminCursorStack.set(newStack);
        this.loadAdmins(prevCursor);
    }

    assignDevice() {
        const sn = this.assignSerialNumber.trim();
        if (!sn) return;
        this.assigning.set(true);
        this.adminService.assignDeviceToTenant(this.tenantId, sn).subscribe({
            next: () => {
                this.messageService.add({ severity: 'success', summary: 'Success', detail: `Device ${sn} assigned to tenant.` });
                this.assignSerialNumber = '';
                this.assigning.set(false);
                this.cursorStack.set([]);
                this.loadDevices(null);
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: err?.error?.message ?? 'Failed to assign device.' });
                this.assigning.set(false);
            }
        });
    }

    viewDevice(serialNumber: string) {
        this.router.navigate(['/admin/devices', serialNumber]);
    }

    goBack() {
        this.router.navigate(['/admin/tenants']);
    }

    adminStatusLabel(status: string): string {
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

    adminStatusSeverity(status: string): TagSeverity {
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

