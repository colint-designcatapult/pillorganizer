import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../environments/environment';

export interface UserProfile {
    sub: string;
    roles: string[];
    email: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
    private http = inject(HttpClient);

    private user$: Observable<UserProfile> | null = null;

    getMe(): Observable<UserProfile> {
        if (!this.user$) {
            this.user$ = this.http
                .get<UserProfile>(`${environment.controlPlaneApiUrl}/user/me`)
                .pipe(shareReplay(1));
        }
        return this.user$;
    }

    isGlobalAdmin(user: UserProfile): boolean {
        return user.roles.includes('admin-global');
    }
}
