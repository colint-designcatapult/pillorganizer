import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

export interface TenantDeviceSummary {
    deviceId: string;
    serialNumber: string | null;
    userId: string;
    subjectId: string | null;
    dosesTaken: number;
    dosesScheduled: number;
}

export interface TenantDevicePage {
    items: TenantDeviceSummary[];
    nextCursor: string | null;
}

export interface DoseHistoryDto {
    logicalDeviceId: string;
    epochWeek: string;
    binId: number;
    scheduledTime: string;
    finalStatus: string;
    resolvedTime: string | null;
    deviceTimeZone: string;
}

export interface ScheduleBinDto {
    binIndex: number;
    dayOfWeek: string;
    genericTime: string;
}

export interface DeviceAdherenceResponse {
    timezone: string;
    weekStart: string;
    scheduleBins: ScheduleBinDto[];
    history: DoseHistoryDto[];
}

@Injectable({ providedIn: 'root' })
export class TenantService {
    private http = inject(HttpClient);

    listDevices(apiBase: string, cursor?: string | null, size = 20, snFilter?: string | null): Observable<TenantDevicePage> {
        const params: Record<string, string | number> = { size };
        if (cursor) params['cursor'] = cursor;
        if (snFilter) params['snFilter'] = snFilter;
        return this.http.get<TenantDevicePage>(`${apiBase}/tenant-admin/devices`, { params });
    }

    getAdherence(apiBase: string, deviceId: string, year: number, month: number): Observable<DeviceAdherenceResponse> {
        return this.http.get<DeviceAdherenceResponse>(
            `${apiBase}/tenant-admin/devices/${encodeURIComponent(deviceId)}/adherence`,
            { params: { year, month } }
        );
    }
}
