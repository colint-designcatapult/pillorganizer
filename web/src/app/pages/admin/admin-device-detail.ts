import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { AdminService, AdminDeviceDetail as AdminDeviceDetailDto } from '@/app/services/admin.service';

@Component({
    selector: 'app-admin-device-detail',
    standalone: true,
    imports: [CommonModule, ButtonModule, TableModule, TagModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="flex flex-col gap-4">
            <div>
                <p-button label="Back to Devices" icon="pi pi-arrow-left" [text]="true" severity="secondary"
                    (click)="goBack()" />
            </div>

            @if (loading()) {
                <div class="card flex justify-center py-10">
                    <i class="pi pi-spin pi-spinner text-4xl text-muted-color"></i>
                </div>
            } @else if (device()) {
                <!-- Device info card -->
                <div class="card">
                    <h2 class="text-2xl font-semibold mb-4">
                        <i class="pi pi-tablet mr-2"></i>{{ device()!.serialNumber }}
                    </h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Serial Number</span>
                            <code class="text-sm">{{ device()!.serialNumber }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Device ID</span>
                            <code class="text-sm">{{ device()!.deviceId }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Tenant</span>
                            <span>{{ device()!.tenantId ?? '—' }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Thing Name</span>
                            <code class="text-sm">{{ device()!.thingName ?? '—' }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Claim ID</span>
                            <code class="text-sm">{{ device()!.claimId ?? '—' }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Created</span>
                            <span>{{ device()!.createdAt | date:'medium' }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Last Modified</span>
                            <span>{{ device()!.lastModified | date:'medium' }}</span>
                        </div>
                    </div>
                </div>

                <!-- Tenant mapping card -->
                <div class="card">
                    <h3 class="text-lg font-semibold mb-3">
                        <i class="pi pi-building mr-2"></i>Tenant Assignment
                    </h3>
                    @if (device()!.tenantMapping) {
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="flex flex-col gap-1">
                                <span class="text-muted-color text-sm font-medium">Tenant ID</span>
                                <code class="text-sm">{{ device()!.tenantMapping!.tenantId }}</code>
                            </div>
                            <div class="flex flex-col gap-1">
                                <span class="text-muted-color text-sm font-medium">Assigned At</span>
                                <span>{{ device()!.tenantMapping!.createdAt | date:'medium' }}</span>
                            </div>
                            <div class="flex flex-col gap-1">
                                <span class="text-muted-color text-sm font-medium">Last Modified</span>
                                <span>{{ device()!.tenantMapping!.lastModified | date:'medium' }}</span>
                            </div>
                        </div>
                    } @else {
                        <p class="text-muted-color text-sm">No tenant mapping found for this device.</p>
                    }
                </div>

                <!-- Claims table -->
                <div class="card">
                    <h3 class="text-lg font-semibold mb-3">
                        <i class="pi pi-key mr-2"></i>Device Claims
                        <span class="text-muted-color text-sm font-normal ml-2">({{ device()!.claims.length }})</span>
                    </h3>
                    @if (device()!.claims.length === 0) {
                        <p class="text-muted-color text-sm">No claims found for this device.</p>
                    } @else {
                        <p-table [value]="device()!.claims" styleClass="p-datatable-sm" [scrollable]="true">
                            <ng-template pTemplate="header">
                                <tr>
                                    <th>Claim ID</th>
                                    <th>User ID</th>
                                    <th>Device ID</th>
                                    <th>Thing Name</th>
                                    <th>Tenant</th>
                                    <th>Claimed At</th>
                                </tr>
                            </ng-template>
                            <ng-template pTemplate="body" let-claim>
                                <tr>
                                    <td><code class="text-xs">{{ claim.claimId }}</code></td>
                                    <td><code class="text-xs">{{ claim.userId ?? '—' }}</code></td>
                                    <td><code class="text-xs">{{ claim.deviceId ?? '—' }}</code></td>
                                    <td>{{ claim.thingName ?? '—' }}</td>
                                    <td>{{ claim.tenantId ?? '—' }}</td>
                                    <td>{{ claim.createdAt | date:'short' }}</td>
                                </tr>
                            </ng-template>
                        </p-table>
                    }
                </div>
            } @else {
                <div class="card">
                    <p class="text-muted-color">Device not found.</p>
                </div>
            }
        </div>
    `
})
export class AdminDeviceDetail implements OnInit {
    device = signal<AdminDeviceDetailDto | null>(null);
    loading = signal(false);

    constructor(
        private route: ActivatedRoute,
        private router: Router,
        private adminService: AdminService
    ) {}

    ngOnInit() {
        const serialNumber = this.route.snapshot.paramMap.get('serialNumber')!;
        this.loading.set(true);
        this.adminService.getDevice(serialNumber).subscribe({
            next: (data) => { this.device.set(data as AdminDeviceDetailDto); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    goBack() {
        this.router.navigate(['/admin/devices']);
    }
}
