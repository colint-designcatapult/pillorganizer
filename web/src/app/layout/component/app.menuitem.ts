import { afterNextRender, Component, computed, inject, input, signal } from '@angular/core';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RippleModule } from 'primeng/ripple';
import { toSignal } from '@angular/core/rxjs-interop';
import { LayoutService } from '@/app/layout/service/layout.service';
import { filter } from 'rxjs/operators';

@Component({
    selector: '[app-menuitem]',
    imports: [CommonModule, RouterModule, RippleModule],
    template: `
        @if (root() && isVisible()) {
            <div class="layout-menuitem-root-text">{{ item().label }}</div>
        }
        @if ((!hasRouterLink() || hasChildren()) && isVisible()) {
            <a [attr.href]="item().url" (click)="itemClick($event)" [ngClass]="item().class" [attr.target]="item().target" tabindex="0" pRipple>
                <i [ngClass]="item().icon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item().label }}</span>
                @if (hasChildren()) {
                    <i class="pi pi-fw pi-angle-down layout-submenu-toggler"></i>
                }
            </a>
        }
        @if (hasRouterLink() && !hasChildren() && isVisible()) {
            <a
                (click)="itemClick($event)"
                [ngClass]="item().class"
                [routerLink]="item().routerLink"
                routerLinkActive="active-route"
                [routerLinkActiveOptions]="item().routerLinkActiveOptions || { paths: 'exact', queryParams: 'ignored', matrixParams: 'ignored', fragment: 'ignored' }"
                [fragment]="item().fragment"
                [queryParamsHandling]="item().queryParamsHandling"
                [preserveFragment]="item().preserveFragment"
                [skipLocationChange]="item().skipLocationChange"
                [replaceUrl]="item().replaceUrl"
                [state]="item().state"
                [queryParams]="item().queryParams"
                [attr.target]="item().target"
                tabindex="0"
                pRipple
            >
                <i [ngClass]="item().icon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item().label }}</span>
            </a>
        }
        @if (hasChildren() && isVisible() && (root() || isOpen())) {
            <ul [animate.enter]="initialized() ? 'p-submenu-enter' : null" [animate.leave]="'p-submenu-leave'" [class.layout-root-submenulist]="root()">
                @for (child of item().items; track child?.label) {
                    <li app-menuitem [item]="child" [root]="false" [class]="child['badgeClass']"></li>
                }
            </ul>
        }
    `,
    host: {
        '[class.active-menuitem]': 'isOpen() && !root()',
        '[class.layout-root-menuitem]': 'root()'
    },
    styles: [
        `
            .p-submenu-enter {
                animation: p-animate-submenu-expand 450ms cubic-bezier(0.86, 0, 0.07, 1) forwards;
            }

            .p-submenu-leave {
                animation: p-animate-submenu-collapse 450ms cubic-bezier(0.86, 0, 0.07, 1) forwards;
            }

            @keyframes p-animate-submenu-expand {
                from {
                    max-height: 0;
                    overflow: hidden;
                }
                to {
                    max-height: 1000px;
                    overflow: visible;
                }
            }

            @keyframes p-animate-submenu-collapse {
                from {
                    max-height: 1000px;
                    overflow: hidden;
                }
                to {
                    max-height: 0;
                    overflow: hidden;
                }
            }
        `
    ]
})
export class AppMenuitem {
    layoutService = inject(LayoutService);
    router = inject(Router);

    item = input<any>(null);
    root = input<boolean>(false);

    isVisible = computed(() => this.item()?.visible !== false);
    hasChildren = computed(() => !!this.item()?.items?.length);
    hasRouterLink = computed(() => !!this.item()?.routerLink);
    initialized = signal(false);

    private navEnd = toSignal(this.router.events.pipe(filter((e) => e instanceof NavigationEnd)));

    /** Auto-expands when the current URL matches any descendant route. */
    isOpen = computed(() => {
        if (this.root()) return true;
        if (!this.hasChildren()) return false;
        this.navEnd(); // re-evaluate on each navigation
        return this.hasActiveDescendant(this.item());
    });

    constructor() {
        afterNextRender(() => this.initialized.set(true));
    }

    private hasActiveDescendant(item: any): boolean {
        if (!item?.items) return false;
        return item.items.some((child: any) => {
            if (child.routerLink) {
                return this.router.isActive(child.routerLink[0], {
                    paths: 'exact',
                    queryParams: 'ignored',
                    matrixParams: 'ignored',
                    fragment: 'ignored'
                });
            }
            return this.hasActiveDescendant(child);
        });
    }

    itemClick(event: Event) {
        const item = this.item();

        if (item?.disabled) {
            event.preventDefault();
            return;
        }

        if (item?.command) {
            item.command({ originalEvent: event, item });
        }

        if (!this.hasChildren()) {
            this.layoutService.layoutState.update((val) => ({
                ...val,
                overlayMenuActive: false,
                mobileMenuActive: false,
                menuHoverActive: false
            }));
        }
    }
}
