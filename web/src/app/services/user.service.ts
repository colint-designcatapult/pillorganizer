import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, shareReplay, tap } from 'rxjs';
import { environment } from '../../environments/environment';

export interface TenantDetails {
    id: string;
    active: boolean | undefined;
    hostname: string;
    apiBase: string;
    name: string | undefined;
}

export interface UserProfile {
    sub: string;
    roles: string[];
    email: string;
    tenants: TenantDetails[] | undefined;
}

@Injectable({ providedIn: 'root' })
export class UserService {
    private http = inject(HttpClient);

    private user$: Observable<UserProfile> | null = null;
    private cachedUser: UserProfile | null = null;

    getMe(): Observable<UserProfile> {
        if (!this.user$) {
            this.user$ = this.http
                .get<UserProfile>(`${environment.controlPlaneApiUrl}/user/me`)
                .pipe(
                    tap(user => this.cachedUser = user),
                    shareReplay(1)
                );
        }
        return this.user$;
    }

    /** Returns the last resolved user profile synchronously, or null if not yet loaded. */
    getCachedUser(): UserProfile | null {
        return this.cachedUser;
    }

    isGlobalAdmin(user: UserProfile): boolean {
        return user?.roles?.includes('admin-global') ?? false;
    }
}
