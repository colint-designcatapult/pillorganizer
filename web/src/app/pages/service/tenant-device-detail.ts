import { Component, OnInit, DestroyRef, signal, computed, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { switchMap, map } from 'rxjs';
import { ButtonModule } from 'primeng/button';
import { TooltipModule } from 'primeng/tooltip';
import { ToastModule } from 'primeng/toast';
import { TagModule } from 'primeng/tag';
import { MessageService } from 'primeng/api';
import { TenantService, DeviceAdherenceResponse, DoseHistoryDto, ScheduleBinDto } from '@/app/services/tenant.service';
import { UserService } from '@/app/services/user.service';

const DAY_ORDER: Record<string, number> = {
    MONDAY: 0, TUESDAY: 1, WEDNESDAY: 2, THURSDAY: 3,
    FRIDAY: 4, SATURDAY: 5, SUNDAY: 6
};
const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

interface GridCell {
    bin: ScheduleBinDto;
    event: DoseHistoryDto | null;
}

interface CalendarDay {
    date: number | null;
    events: DoseHistoryDto[];
}

@Component({
    selector: 'app-tenant-device-detail',
    standalone: true,
    imports: [CommonModule, ButtonModule, TooltipModule, ToastModule, TagModule],
    providers: [MessageService],
    template: `
        <p-toast />
        <div class="flex flex-col gap-4">
            <div>
                <p-button label="Back to Devices" icon="pi pi-arrow-left" [text]="true" severity="secondary"
                    (click)="goBack()" />
            </div>

            <div class="card">
                <h2 class="text-2xl font-semibold mb-1">
                    <i class="pi pi-tablet mr-2"></i>{{ deviceId }}
                </h2>
            </div>

            @if (loading()) {
                <div class="card flex justify-center py-10">
                    <i class="pi pi-spin pi-spinner text-4xl text-muted-color"></i>
                </div>
            } @else if (currentData()) {

                <!-- Current Week Table -->
                <div class="card overflow-x-auto">
                    <h3 class="text-lg font-semibold mb-1">Current Week</h3>
                    <p class="text-sm text-muted-color mb-3">Week of {{ weekLabel() }}</p>
                    @if (gridRows().length === 0) {
                        <p class="text-muted-color text-sm">No schedule configured for this device.</p>
                    } @else {
                        <table class="w-full text-sm border-collapse">
                            <thead>
                                <tr>
                                    <th class="text-left text-muted-color font-medium px-2 py-2 border-b border-surface">Slot</th>
                                    @for (day of dayLabels; track day) {
                                        <th class="text-center text-muted-color font-medium px-2 py-2 border-b border-surface">{{ day }}</th>
                                    }
                                </tr>
                            </thead>
                            <tbody>
                                @for (row of gridRows(); track $index) {
                                    <tr class="border-b border-surface">
                                        <td class="px-2 py-3 font-medium text-muted-color whitespace-nowrap">
                                            {{ $index === 0 ? 'AM' : 'PM' }}
                                        </td>
                                        @for (cell of row; track $index) {
                                            <td class="px-2 py-3 text-center align-top">
                                                @if (cell) {
                                                    <div class="flex flex-col items-center gap-1">
                                                        @if (cell.event?.finalStatus === 'TAKEN' || cell.event?.finalStatus === 'TAKE_NOW') {
                                                            <span class="text-green-500 font-bold text-base"
                                                                [pTooltip]="cell.event!.finalStatus" tooltipPosition="top">✓</span>
                                                        } @else if (cell.event?.finalStatus === 'MISSED') {
                                                            <span class="text-red-500 font-bold text-base"
                                                                pTooltip="MISSED" tooltipPosition="top">✗</span>
                                                        } @else {
                                                            <span class="text-muted-color text-base">·</span>
                                                        }
                                                        <!-- Actual resolved time in device timezone -->
                                                        <span class="text-xs text-muted-color">
                                                            {{ cell.event?.resolvedTime ? formatTime(cell.event!.resolvedTime!, cell.event!.deviceTimeZone) : '—' }}
                                                        </span>
                                                        <!-- Generic schedule time -->
                                                        <span class="text-xs font-medium">{{ cell.bin.genericTime }}</span>
                                                    </div>
                                                } @else {
                                                    <span class="text-muted-color">—</span>
                                                }
                                            </td>
                                        }
                                    </tr>
                                }
                            </tbody>
                        </table>
                        <div class="flex gap-4 mt-4 text-xs text-muted-color">
                            <span><span class="text-green-500 font-bold">✓</span> Taken</span>
                            <span><span class="text-red-500 font-bold">✗</span> Missed</span>
                            <span><span class="text-muted-color">·</span> Pending / no data</span>
                            <span class="ml-4 italic">Middle: actual time · Bottom: scheduled time</span>
                        </div>
                    }
                </div>

                <!-- Monthly Calendar -->
                <div class="card">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold">Adherence History</h3>
                        <div class="flex items-center gap-2">
                            <p-button icon="pi pi-chevron-left" [text]="true" severity="secondary" (click)="prevMonth()" />
                            <span class="font-medium w-40 text-center">{{ monthName() }} {{ viewYear() }}</span>
                            <p-button icon="pi pi-chevron-right" [text]="true" severity="secondary" (click)="nextMonth()" />
                        </div>
                    </div>

                    @if (calLoading()) {
                        <div class="flex justify-center py-6">
                            <i class="pi pi-spin pi-spinner text-2xl text-muted-color"></i>
                        </div>
                    } @else {
                        <div class="grid grid-cols-7 gap-1 text-center text-xs font-medium text-muted-color mb-1">
                            @for (d of dayLabels; track d) { <div>{{ d }}</div> }
                        </div>
                        @for (week of calendarWeeks(); track $index) {
                            <div class="grid grid-cols-7 gap-1 mb-1">
                                @for (day of week; track $index) {
                                    <div class="min-h-16 rounded p-1 text-xs"
                                        [class]="day.date ? 'bg-surface-100 dark:bg-surface-800' : ''">
                                        @if (day.date) {
                                            <div class="font-medium mb-1">{{ day.date }}</div>
                                            <div class="flex flex-wrap gap-0.5 justify-center">
                                                @for (ev of day.events; track $index) {
                                                    <span class="w-2 h-2 rounded-full inline-block"
                                                        [class]="dotClass(ev.finalStatus)"
                                                        [pTooltip]="ev.finalStatus + ' ' + formatTime(ev.resolvedTime ?? ev.scheduledTime, ev.deviceTimeZone)"
                                                        tooltipPosition="top"></span>
                                                }
                                            </div>
                                        }
                                    </div>
                                }
                            </div>
                        }
                        <div class="flex gap-4 mt-3 text-xs text-muted-color">
                            <span><span class="inline-block w-2 h-2 rounded-full bg-green-500 mr-1"></span>Taken</span>
                            <span><span class="inline-block w-2 h-2 rounded-full bg-red-500 mr-1"></span>Missed</span>
                            <span><span class="inline-block w-2 h-2 rounded-full bg-yellow-400 mr-1"></span>Other</span>
                        </div>
                    }
                </div>
            }
        </div>
    `
})
export class TenantDeviceDetail implements OnInit {
    deviceId = '';
    tenantId = '';
    apiBase = '';

    loading = signal(false);
    calLoading = signal(false);

    /** Current month data: schedule + history used for the weekly table */
    currentData = signal<DeviceAdherenceResponse | null>(null);

    /** History for the currently viewed calendar month */
    calHistory = signal<DoseHistoryDto[] | null>(null);

    viewYear = signal(new Date().getFullYear());
    viewMonth = signal(new Date().getMonth() + 1);

    private readonly currentYear = new Date().getFullYear();
    private readonly currentMonth = new Date().getMonth() + 1;

    readonly dayLabels = DAY_LABELS;

    private tenantService = inject(TenantService);
    private userService = inject(UserService);
    private route = inject(ActivatedRoute);
    private router = inject(Router);
    private destroyRef = inject(DestroyRef);

    weekLabel = computed(() => {
        const d = this.currentData();
        if (!d) return '';
        return new Date(d.weekStart).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    });

    monthName = computed(() => MONTH_NAMES[this.viewMonth() - 1]);

    /** 2×7 grid built from current week's history + schedule bins.
     *  Device bin scheme: binId = day*2 → PM,  day*2+1 → AM  (day 0=Mon … 6=Sun)
     */
    gridRows = computed<(GridCell | null)[][]>(() => {
        const data = this.currentData();
        if (!data || !data.scheduleBins?.length) return [];

        const weekStartMs = new Date(data.weekStart).getTime();
        const weekEndMs = weekStartMs + 7 * 24 * 60 * 60 * 1000;

        // Map device binId → event (filtered to the week window)
        const eventMap = new Map<number, DoseHistoryDto>();
        for (const ev of data.history) {
            const t = new Date(ev.scheduledTime).getTime();
            if (t >= weekStartMs && t < weekEndMs) {
                if (!eventMap.has(ev.binId)) eventMap.set(ev.binId, ev);
            }
        }

        // For each day, collect generic times sorted ascending (AM first, PM second)
        const DAY_NAMES = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
        const scheduleTimesByDay: string[][] = Array.from({ length: 7 }, () => []);
        for (const bin of data.scheduleBins) {
            const di = DAY_ORDER[bin.dayOfWeek] ?? -1;
            if (di >= 0) scheduleTimesByDay[di].push(bin.genericTime);
        }
        for (const times of scheduleTimesByDay) times.sort(); // '06:30' < '17:00'

        // Row 0 = AM, Row 1 = PM
        // AM binId = day*2+1, PM binId = day*2
        const rows: (GridCell | null)[][] = [Array(7).fill(null), Array(7).fill(null)];
        for (let day = 0; day < 7; day++) {
            const amBinId = day * 2 + 1;
            const pmBinId = day * 2;
            rows[0][day] = {
                bin: { binIndex: amBinId, dayOfWeek: DAY_NAMES[day], genericTime: scheduleTimesByDay[day][0] ?? '—' },
                event: eventMap.get(amBinId) ?? null
            };
            rows[1][day] = {
                bin: { binIndex: pmBinId, dayOfWeek: DAY_NAMES[day], genericTime: scheduleTimesByDay[day][1] ?? '—' },
                event: eventMap.get(pmBinId) ?? null
            };
        }
        return rows;
    });

    /** Calendar weeks for the viewed month */
    calendarWeeks = computed<CalendarDay[][]>(() => {
        const history = this.calHistory();
        const data = this.currentData();
        if (history === null) return [];

        const tz = data?.timezone ?? 'UTC';
        const year = this.viewYear();
        const month = this.viewMonth();

        // Group events by local date string (YYYY-MM-DD in device tz)
        const byDate = new Map<string, DoseHistoryDto[]>();
        for (const ev of history) {
            const key = new Date(ev.scheduledTime).toLocaleDateString('en-CA', { timeZone: tz });
            if (!byDate.has(key)) byDate.set(key, []);
            byDate.get(key)!.push(ev);
        }

        const firstDay = new Date(year, month - 1, 1).getDay(); // 0=Sun
        const startOffset = (firstDay + 6) % 7; // Mon-based offset
        const daysInMonth = new Date(year, month, 0).getDate();

        const weeks: CalendarDay[][] = [];
        let week: CalendarDay[] = [];

        for (let i = 0; i < startOffset; i++) week.push({ date: null, events: [] });

        for (let d = 1; d <= daysInMonth; d++) {
            const key = `${year}-${String(month).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
            week.push({ date: d, events: byDate.get(key) ?? [] });
            if (week.length === 7) { weeks.push(week); week = []; }
        }
        while (week.length > 0 && week.length < 7) week.push({ date: null, events: [] });
        if (week.length) weeks.push(week);

        return weeks;
    });

    ngOnInit() {
        this.route.paramMap.pipe(
            switchMap(params => {
                this.tenantId = params.get('tenantId')!;
                this.deviceId = params.get('deviceId')!;
                this.currentData.set(null);
                this.calHistory.set(null);
                this.viewYear.set(this.currentYear);
                this.viewMonth.set(this.currentMonth);
                return this.userService.getMe().pipe(
                    map(user => user.tenants?.find(t => t.id === this.tenantId)?.apiBase ?? '')
                );
            }),
            takeUntilDestroyed(this.destroyRef)
        ).subscribe(apiBase => {
            this.apiBase = apiBase;
            this.loadCurrentMonth();
        });
    }

    prevMonth() {
        let y = this.viewYear(), m = this.viewMonth() - 1;
        if (m < 1) { m = 12; y--; }
        this.viewYear.set(y); this.viewMonth.set(m);
        this.loadCalMonth(y, m);
    }

    nextMonth() {
        let y = this.viewYear(), m = this.viewMonth() + 1;
        if (m > 12) { m = 1; y++; }
        this.viewYear.set(y); this.viewMonth.set(m);
        this.loadCalMonth(y, m);
    }

    formatTime(isoString: string, timezone?: string): string {
        try {
            return new Intl.DateTimeFormat('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false,
                timeZone: timezone ?? Intl.DateTimeFormat().resolvedOptions().timeZone
            }).format(new Date(isoString));
        } catch {
            return '—';
        }
    }

    dotClass(status: string): string {
        if (status === 'TAKEN' || status === 'TAKE_NOW') return 'bg-green-500';
        if (status === 'MISSED') return 'bg-red-500';
        return 'bg-yellow-400';
    }

    private loadCurrentMonth() {
        if (!this.apiBase) return;
        this.loading.set(true);
        this.tenantService.getAdherence(this.apiBase, this.deviceId, this.currentYear, this.currentMonth).subscribe({
            next: (data) => {
                this.currentData.set(data);
                this.calHistory.set(data.history);
                this.loading.set(false);
            },
            error: () => this.loading.set(false)
        });
    }

    private loadCalMonth(year: number, month: number) {
        if (!this.apiBase) return;
        // If navigating back to current month, reuse loaded data
        if (year === this.currentYear && month === this.currentMonth && this.currentData()) {
            this.calHistory.set(this.currentData()!.history);
            return;
        }
        this.calLoading.set(true);
        this.tenantService.getAdherence(this.apiBase, this.deviceId, year, month).subscribe({
            next: (data) => { this.calHistory.set(data.history); this.calLoading.set(false); },
            error: () => this.calLoading.set(false)
        });
    }

    goBack() {
        this.router.navigate(['/tenant', this.tenantId, 'devices']);
    }
}

