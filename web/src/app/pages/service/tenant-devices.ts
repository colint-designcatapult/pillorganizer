import { Component, OnInit, DestroyRef, signal, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, switchMap } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { TenantService, TenantDeviceSummary } from '@/app/services/tenant.service';
import { UserService } from '@/app/services/user.service';

@Component({
    selector: 'app-tenant-devices',
    standalone: true,
    imports: [CommonModule, FormsModule, TableModule, ButtonModule, InputTextModule, InputIconModule, IconFieldModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="card">
            <p-table [value]="devices()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="deviceId">
                <ng-template #caption>
                    <div class="flex justify-between items-center flex-wrap gap-3">
                        <span class="text-2xl font-semibold">Devices — {{ tenantId }}</span>
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
                        <th>Subject ID</th>
                        <th>Adherence (this month)</th>
                        <th style="width:4rem"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-device>
                    <tr class="cursor-pointer" (click)="openDevice(device)">
                        <td><code class="text-sm">{{ device.serialNumber ?? '—' }}</code></td>
                        <td><code class="text-sm">{{ device.subjectId }}</code></td>
                        <td>{{ device.dosesTaken }} / {{ device.dosesScheduled }}</td>
                        <td>
                            <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true" severity="secondary"
                                (click)="openDevice(device); $event.stopPropagation()" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="4" class="text-center text-muted-color py-6">No devices found.</td></tr>
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
export class TenantDevices implements OnInit {
    devices = signal<TenantDeviceSummary[]>([]);
    nextCursor = signal<string | null>(null);
    cursorStack = signal<(string | null)[]>([]);
    loading = signal(false);

    tenantId = '';
    apiBase = '';
    snFilterValue = '';
    private filterSubject = new Subject<string>();
    readonly pageSize = 20;

    private tenantService = inject(TenantService);
    private userService = inject(UserService);
    private route = inject(ActivatedRoute);
    private router = inject(Router);
    private destroyRef = inject(DestroyRef);

    ngOnInit() {
        this.route.paramMap.pipe(
            switchMap(params => {
                this.tenantId = params.get('tenantId')!;
                this.snFilterValue = '';
                this.cursorStack.set([]);
                this.devices.set([]);
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
            distinctUntilChanged(),
            takeUntilDestroyed(this.destroyRef)
        ).subscribe(() => {
            this.cursorStack.set([]);
            this.load(null);
        });
    }

    onFilterChange(value: string) { this.filterSubject.next(value); }
    clearFilter() { this.snFilterValue = ''; this.filterSubject.next(''); }

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
        if (!this.apiBase) return;
        this.loading.set(true);
        this.tenantService.listDevices(this.apiBase, cursor, this.pageSize, this.snFilterValue || null).subscribe({
            next: (data) => { this.devices.set(data.items); this.nextCursor.set(data.nextCursor); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    openDevice(device: TenantDeviceSummary) {
        this.router.navigate(['/tenant', this.tenantId, 'devices', device.deviceId]);
    }
}
