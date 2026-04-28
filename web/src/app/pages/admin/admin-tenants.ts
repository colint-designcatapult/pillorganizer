import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { AdminService, AdminTenantSummary } from '@/app/services/admin.service';

@Component({
    selector: 'app-admin-tenants',
    standalone: true,
    imports: [CommonModule, ButtonModule, TableModule, TagModule, ToastModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="card">
            <p-table [value]="tenants()" [loading]="loading()" [rowHover]="true" [showGridlines]="true" dataKey="id">
                <ng-template #caption>
                    <span class="text-2xl font-semibold">Tenants</span>
                </ng-template>
                <ng-template #header>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Hostname</th>
                        <th>Status</th>
                        <th style="width:4rem"></th>
                    </tr>
                </ng-template>
                <ng-template #body let-tenant>
                    <tr class="cursor-pointer" (click)="viewTenant(tenant.id)">
                        <td><code class="text-sm">{{ tenant.id }}</code></td>
                        <td>{{ tenant.name }}</td>
                        <td>{{ tenant.hostname }}</td>
                        <td>
                            <p-tag [value]="tenant.active ? 'Active' : 'Inactive'"
                                   [severity]="tenant.active ? 'success' : 'danger'" />
                        </td>
                        <td>
                            <p-button icon="pi pi-arrow-right" [rounded]="true" [text]="true" severity="secondary"
                                (click)="viewTenant(tenant.id); $event.stopPropagation()" />
                        </td>
                    </tr>
                </ng-template>
                <ng-template #emptymessage>
                    <tr><td colspan="5" class="text-center text-muted-color py-6">No tenants configured.</td></tr>
                </ng-template>
            </p-table>
        </div>
    `
})
export class AdminTenants implements OnInit {
    tenants = signal<AdminTenantSummary[]>([]);
    loading = signal(false);

    constructor(
        private router: Router,
        private adminService: AdminService
    ) {}

    ngOnInit() {
        this.loading.set(true);
        this.adminService.listTenants().subscribe({
            next: (data) => { this.tenants.set(data); this.loading.set(false); },
            error: () => this.loading.set(false)
        });
    }

    viewTenant(tenantId: string) {
        this.router.navigate(['/admin/tenants', tenantId]);
    }
}
