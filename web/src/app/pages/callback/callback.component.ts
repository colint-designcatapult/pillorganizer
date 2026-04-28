import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { OidcSecurityService } from 'angular-auth-oidc-client';

@Component({
    selector: 'app-callback',
    standalone: true,
    template: `<div class="flex items-center justify-center h-screen">
        <p class="text-lg text-gray-600">Signing you in…</p>
    </div>`
})
export class CallbackComponent implements OnInit {
    constructor(
        private oidcSecurityService: OidcSecurityService,
        private router: Router
    ) {}

    ngOnInit(): void {
        this.oidcSecurityService.checkAuth().subscribe(({ isAuthenticated }) => {
            if (isAuthenticated) {
                this.router.navigateByUrl('/');
            }
        });
    }
}
