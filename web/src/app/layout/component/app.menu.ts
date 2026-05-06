import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from './app.menuitem';
import { UserService } from '@/app/services/user.service';

const ADMIN_SECTION: MenuItem = {
    label: 'Global',
    items: [
        { label: 'Users', icon: 'pi pi-fw pi-users', routerLink: ['/admin/users'] },
        { label: 'Devices', icon: 'pi pi-fw pi-tablet', routerLink: ['/admin/devices'] },
        { label: 'Tenants', icon: 'pi pi-fw pi-building', routerLink: ['/admin/tenants'] },
        { label: 'Administrators', icon: 'pi pi-fw pi-shield', routerLink: ['/admin/administrators'] }
    ]
};

@Component({
    selector: 'app-menu',
    standalone: true,
    imports: [CommonModule, AppMenuitem, RouterModule],
    template: `<ul class="layout-menu">
        @for (item of model(); track item.label) {
            @if (!item.separator) {
                <li app-menuitem [item]="item" [root]="true"></li>
            } @else {
                <li class="menu-separator"></li>
            }
        }
    </ul>`
})
export class AppMenu {
    private userService = inject(UserService);
    private user = toSignal(this.userService.getMe());

    model = computed<MenuItem[]>(() => {
        const user = this.user();
        const sections: MenuItem[] = [];

        if (user && this.userService.isGlobalAdmin(user)) {
            sections.push(ADMIN_SECTION);
        }

        if (user?.tenants?.length) {
            for (const tenant of user.tenants) {
                sections.push({
                    label: tenant.id,
                    items: [
                        { label: 'Adherence', icon: 'pi pi-fw pi-chart-bar', routerLink: ['/tenant', tenant.id, 'devices'] }
                    ]
                });
            }
        }

        return [...sections];
    });
}
