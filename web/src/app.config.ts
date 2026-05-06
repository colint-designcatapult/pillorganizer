import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideZonelessChangeDetection } from '@angular/core';
import { provideRouter, withEnabledBlockingInitialNavigation, withInMemoryScrolling } from '@angular/router';
import Aura from '@primeuix/themes/aura';
import { authInterceptor, provideAuth, withAppInitializerAuthCheck } from 'angular-auth-oidc-client';
import { providePrimeNG } from 'primeng/config';
import { environment } from './environments/environment';
import { appRoutes } from './app.routes';
import { tenantAuthInterceptor } from './app/interceptors/tenant-auth.interceptor';

export const appConfig: ApplicationConfig = {
    providers: [
        provideRouter(appRoutes, withInMemoryScrolling({ anchorScrolling: 'enabled', scrollPositionRestoration: 'enabled' }), withEnabledBlockingInitialNavigation()),
        provideHttpClient(withFetch(), withInterceptors([authInterceptor(), tenantAuthInterceptor])),
        provideZonelessChangeDetection(),
        providePrimeNG({ theme: { preset: Aura, options: { darkModeSelector: '.app-dark' } } }),
        provideAuth(
            {
                config: {
                    authority: 'https://cognito-idp.ca-central-1.amazonaws.com/ca-central-1_liR9FZX79',
                    redirectUrl: environment.redirectUrl,
                    clientId: '1dorh2ohkeif3tl0dn5s3glp1n',
                    scope: 'email openid profile',
                    responseType: 'code',
                    secureRoutes: [environment.controlPlaneApiUrl]
                }
            },
            withAppInitializerAuthCheck()
        )
    ]
};
