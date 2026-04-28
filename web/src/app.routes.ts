import { Routes } from '@angular/router';
import { AppLayout } from './app/layout/component/app.layout';
import { CallbackComponent } from './app/pages/callback/callback.component';
import { Dashboard } from './app/pages/dashboard/dashboard';
import { Documentation } from './app/pages/documentation/documentation';
import { Landing } from './app/pages/landing/landing';
import { Notfound } from './app/pages/notfound/notfound';
import { AdminDevices } from './app/pages/admin/admin-devices';
import { AdminUsers } from './app/pages/admin/admin-users';
import { AdminUserDetail } from './app/pages/admin/admin-user-detail';
import { AdminDeviceDetail } from './app/pages/admin/admin-device-detail';
import { AdminTenants } from './app/pages/admin/admin-tenants';
import { AdminTenantDetail } from './app/pages/admin/admin-tenant-detail';
import { authGuard } from './app/guards/auth.guard';

export const appRoutes: Routes = [
    {
        path: '',
        component: AppLayout,
        canActivate: [authGuard],
        children: [
            { path: '', component: Dashboard },
            { path: 'uikit', loadChildren: () => import('./app/pages/uikit/uikit.routes') },
            { path: 'documentation', component: Documentation },
            { path: 'pages', loadChildren: () => import('./app/pages/pages.routes') },
            { path: 'admin/users', component: AdminUsers },
            { path: 'admin/users/:userId', component: AdminUserDetail },
            { path: 'admin/devices', component: AdminDevices },
            { path: 'admin/devices/:serialNumber', component: AdminDeviceDetail },
            { path: 'admin/tenants', component: AdminTenants },
            { path: 'admin/tenants/:tenantId', component: AdminTenantDetail }
        ]
    },
    { path: 'landing', component: Landing },
    { path: 'notfound', component: Notfound },
    { path: 'callback', component: CallbackComponent },
    { path: 'auth', loadChildren: () => import('./app/pages/auth/auth.routes') },
    { path: '**', redirectTo: '/notfound' }
];

