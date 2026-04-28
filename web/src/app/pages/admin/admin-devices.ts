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
import { AdminService, AdminDeviceSummary } from '@/app/services/admin.service';

@Component({
    selector: 'app-admin-devices',
    standalone: true,
    imports: [CommonModule, FormsModule, TableModule, ButtonModule, InputTextModule, InputIconModule, IconFieldModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="card">
            <p-table [value]="devices()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="serialNumber">
                <ng-template #caption>
                    <div class="flex justify-between items-center flex-wrap gap-3">
                        <span class="text-2xl font-semibold">Devices</span>
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
                        <th>Tenant</th>
                        <th>Thing Name</th>
                        <th>Created</th>
                        <th style="width:4rem"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-device>
                    <tr class="cursor-pointer" (click)="openDevice(device)">
                        <td><code class="text-sm">{{ device.serialNumber }}</code></td>
                        <td><code class="text-sm">{{ device.deviceId }}</code></td>
                        <td>{{ device.tenantId ?? '—' }}</td>
                        <td>{{ device.thingName ?? '—' }}</td>
                        <td>{{ device.createdAt | date:'short' }}</td>
                        <td>
                            <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true" severity="secondary"
                                (click)="openDevice(device); $event.stopPropagation()" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="6" class="text-center text-muted-color py-6">No devices found.</td></tr>
                </ng-template>
                <ng-template #footer>
                    <tr>
                        <td colspan="6">
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
export class AdminDevices implements OnInit {
    devices = signal<AdminDeviceSummary[]>([]);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);
    loading = signal(false);

    snFilterValue = '';
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
        this.snFilterValue = '';
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
        this.adminService.listDevices(cursor, this.pageSize, this.snFilterValue || null).subscribe({
            next: (data) => { this.devices.set(data.items); this.nextCursor.set(data.nextCursor); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    openDevice(device: AdminDeviceSummary) {
        this.router.navigate(['/admin/devices', device.serialNumber]);
    }
}
