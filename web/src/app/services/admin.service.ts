import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface AdminUserSummary {
    userId: string;
    userName: string | null;
    email: string;
    createdAt: string;
}

export interface AdminDeviceSummary {
    serialNumber: string;
    deviceId: string;
    tenantId: string | null;
    thingName: string | null;
    createdAt: string;
}

export interface AdminDeviceClaimSummary {
    serialNumber: string;
    claimId: string;
    userId: string | null;
    deviceId: string | null;
    thingName: string | null;
    tenantId: string | null;
    createdAt: string | null;
}

export interface AdminDeviceTenantMapping {
    serialNumber: string;
    tenantId: string;
    createdAt: string | null;
    lastModified: string | null;
}

export interface AdminUserDetail {
    userId: string;
    userName: string | null;
    email: string;
    userSub: string;
    fcmEndpointArn: string | null;
    createdAt: string;
    lastModified: string;
    devices: AdminDeviceSummary[];
}

export interface AdminDeviceDetail {
    serialNumber: string;
    deviceId: string;
    tenantId: string | null;
    thingName: string | null;
    claimId: string | null;
    createdAt: string;
    lastModified: string;
    claims: AdminDeviceClaimSummary[];
    tenantMapping: AdminDeviceTenantMapping | null;
}

export interface AdminUserPage {
    items: AdminUserSummary[];
    nextCursor: string | null;
}

export interface AdminDevicePage {
    items: AdminDeviceSummary[];
    nextCursor: string | null;
}

export interface AdminTenantSummary {
    id: string;
    name: string;
    hostname: string;
    active: boolean;
}

export interface AdminTenantDetail {
    id: string;
    name: string;
    hostname: string;
    active: boolean;
}

export interface AdminTenantDeviceRow {
    serialNumber: string;
    tenantId: string;
    deviceId: string | null;
    thingName: string | null;
    claimId: string | null;
    mappingCreatedAt: string | null;
    deviceCreatedAt: string | null;
}

export interface AdminTenantDevicePage {
    items: AdminTenantDeviceRow[];
    nextCursor: string | null;
}

@Injectable({ providedIn: 'root' })
export class AdminService {
    private http = inject(HttpClient);
    private base = environment.controlPlaneApiUrl;

    listUsers(cursor?: string | null, size = 20, userIdFilter?: string | null): Observable<AdminUserPage> {
        const params: Record<string, string | number> = { size };
        if (cursor) params['cursor'] = cursor;
        if (userIdFilter) params['userIdFilter'] = userIdFilter;
        return this.http.get<AdminUserPage>(`${this.base}/admin/users`, { params });
    }

    getUser(userId: string): Observable<AdminUserDetail> {
        return this.http.get<AdminUserDetail>(`${this.base}/admin/users/${userId}`);
    }

    listDevices(cursor?: string | null, size = 20, snFilter?: string | null): Observable<AdminDevicePage> {
        const params: Record<string, string | number> = { size };
        if (cursor) params['cursor'] = cursor;
        if (snFilter) params['snFilter'] = snFilter;
        return this.http.get<AdminDevicePage>(`${this.base}/admin/devices`, { params });
    }

    getDevice(serialNumber: string): Observable<AdminDeviceDetail> {
        return this.http.get<AdminDeviceDetail>(`${this.base}/admin/devices/${encodeURIComponent(serialNumber)}`);
    }

    listTenants(): Observable<AdminTenantSummary[]> {
        return this.http.get<AdminTenantSummary[]>(`${this.base}/admin/tenants`);
    }

    getTenant(tenantId: string): Observable<AdminTenantDetail> {
        return this.http.get<AdminTenantDetail>(`${this.base}/admin/tenants/${tenantId}`);
    }

    getTenantDevices(tenantId: string, cursor?: string | null, size = 20, snFilter?: string | null): Observable<AdminTenantDevicePage> {
        const params: Record<string, string | number> = { size };
        if (cursor) params['cursor'] = cursor;
        if (snFilter) params['snFilter'] = snFilter;
        return this.http.get<AdminTenantDevicePage>(`${this.base}/admin/tenants/${tenantId}/devices`, { params });
    }

    assignDeviceToTenant(tenantId: string, serialNumber: string): Observable<AdminDeviceTenantMapping> {
        return this.http.post<AdminDeviceTenantMapping>(
            `${this.base}/admin/tenants/${tenantId}/device-mappings`,
            { serialNumber }
        );
    }
}
