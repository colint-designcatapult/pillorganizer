import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { switchMap, take } from 'rxjs/operators';
import { UserService } from '../services/user.service';

/**
 * Attaches the OIDC access token to requests whose URL matches a tenant's apiBase.
 * The built-in authInterceptor() only covers statically configured secureRoutes;
 * tenant URLs are dynamic so we handle them here.
 */
export const tenantAuthInterceptor: HttpInterceptorFn = (req, next) => {
    const userService = inject(UserService);
    const oidc = inject(OidcSecurityService);

    const user = userService.getCachedUser();
    const isTenantRequest = user?.tenants?.some(t => t.apiBase && req.url.startsWith(t.apiBase)) ?? false;

    if (!isTenantRequest) {
        return next(req);
    }

    return oidc.getAccessToken().pipe(
        take(1),
        switchMap(token => {
            const authed = token
                ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
                : req;
            return next(authed);
        })
    );
};
