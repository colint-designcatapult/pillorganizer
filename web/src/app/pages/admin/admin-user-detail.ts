import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { AdminService, AdminUserDetail as AdminUserDetailDto } from '@/app/services/admin.service';

@Component({
    selector: 'app-admin-user-detail',
    standalone: true,
    imports: [CommonModule, ButtonModule, TableModule, TagModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="flex flex-col gap-4">
            <!-- Back button -->
            <div>
                <p-button label="Back to Users" icon="pi pi-arrow-left" [text]="true" severity="secondary"
                    (click)="goBack()" />
            </div>

            @if (loading()) {
                <div class="card flex justify-center py-10">
                    <i class="pi pi-spin pi-spinner text-4xl text-muted-color"></i>
                </div>
            } @else if (user()) {
                <!-- User details card -->
                <div class="card">
                    <h2 class="text-2xl font-semibold mb-4">
                        <i class="pi pi-user mr-2"></i>{{ user()!.email }}
                    </h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">User ID</span>
                            <code class="text-sm">{{ user()!.userId }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Username</span>
                            <span>{{ user()!.userName ?? '—' }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Email</span>
                            <span>{{ user()!.email }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Cognito Subject</span>
                            <code class="text-sm">{{ user()!.userSub }}</code>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">FCM Endpoint ARN</span>
                            <span class="text-sm break-all">{{ user()!.fcmEndpointArn ?? '—' }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Created</span>
                            <span>{{ user()!.createdAt | date:'medium' }}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-muted-color text-sm font-medium">Last Modified</span>
                            <span>{{ user()!.lastModified | date:'medium' }}</span>
                        </div>
                    </div>
                </div>

                <!-- Devices card -->
                <div class="card">
                    <h3 class="text-lg font-semibold mb-4">
                        <i class="pi pi-tablet mr-2"></i>Devices ({{ user()!.devices.length }})
                    </h3>
                    <p-table [value]="user()!.devices" [rowHover]="true" dataKey="serialNumber">
                        <ng-template #header>
                            <tr>
                                <th>Serial Number</th>
                                <th>Device ID</th>
                                <th>Tenant</th>
                                <th>Thing Name</th>
                                <th>Claimed</th>
                                <th style="width:6rem"></th>
                            </tr>
                        </ng-template>
                        <ng-template #body let-device>
                            <tr class="cursor-pointer" (click)="openDevice(device.serialNumber)">
                                <td><code class="text-sm">{{ device.serialNumber }}</code></td>
                                <td><code class="text-sm">{{ device.deviceId }}</code></td>
                                <td>{{ device.tenantId ?? '—' }}</td>
                                <td>{{ device.thingName ?? '—' }}</td>
                                <td>{{ device.createdAt | date:'short' }}</td>
                                <td>
                                    <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true"
                                        severity="secondary"
                                        (click)="openDevice(device.serialNumber); $event.stopPropagation()" />
                                </td>
                            </tr>
                        </ng-template>
                        <ng-template #emptymessage>
                            <tr><td colspan="6" class="text-center text-muted-color py-6">No devices linked to this user.</td></tr>
                        </ng-template>
                    </p-table>
                </div>
            } @else {
                <div class="card">
                    <p class="text-muted-color">User not found.</p>
                </div>
            }
        </div>
    `
})
export class AdminUserDetail implements OnInit {
    user = signal<AdminUserDetailDto | null>(null);
    loading = signal(false);

    constructor(
        private route: ActivatedRoute,
        private router: Router,
        private adminService: AdminService
    ) {}

    ngOnInit() {
        const userId = this.route.snapshot.paramMap.get('userId')!;
        this.loading.set(true);
        this.adminService.getUser(userId).subscribe({
            next: (data) => { this.user.set(data as AdminUserDetailDto); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    goBack() {
        this.router.navigate(['/admin/users']);
    }

    openDevice(serialNumber: string) {
        this.router.navigate(['/admin/devices', serialNumber]);
    }
}
