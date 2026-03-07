import 'package:app/navigation/tab_bar.dart';
import 'package:app/navigation/tab_bar_item.dart';
import 'package:app/provider/deep_link_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/tab/account.dart';
import 'package:app/screens/tab/home.dart';
import 'package:app/screens/tab/my_devices.dart';
import 'package:app/screens/tab/pills_screen.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/device_connection_status_provider.dart';
import '../provider/device_notice_provider.dart';
import '../provider/device_state_provider.dart';
import '../provider/scroll_provider.dart';
import '../provider/time_provider.dart';

const Color backgroundColor = Color(0xFF206B8B);
const Color activeColor = Color(0xFFBFD2DB);

enum TabType { home, pills, devices, account }

class TabNavigator extends ConsumerStatefulWidget {
  const TabNavigator({Key? key}) : super(key: key);

  @override
  ConsumerState<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends ConsumerState<TabNavigator> {
  TabType _currentTab = TabType.home;

  List<TabType> _getAvailableTabs(bool isOwner, bool hasDevice) {
    if (!hasDevice) {
      return [TabType.home, TabType.account];
    } else if (isOwner) {
      return [TabType.home, TabType.pills, TabType.devices, TabType.account];
    } else {
      return [TabType.home, TabType.devices, TabType.account];
    }
  }

  int _getTabIndex(TabType tab, bool isOwner, bool hasDevice) {
    final availableTabs = _getAvailableTabs(isOwner, hasDevice);
    return availableTabs.indexOf(tab);
  }

  Widget _getTabWidget(TabType tab) {
    switch (tab) {
      case TabType.home:
        return Builder(
            key: const ValueKey('home'),
            builder: (context) => const HomeScreen());
      case TabType.pills:
        return Builder(
            key: const ValueKey('pills'),
            builder: (context) => const PillsScreen());
      case TabType.devices:
        return Builder(
            key: const ValueKey('devices'),
            builder: (context) => const MyDevicesScreen());
      case TabType.account:
        return Builder(
            key: const ValueKey('account'),
            builder: (context) => const AccountScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceListProvider.notifier).refresh();
      _checkForPendingNavigation();
    });
  }

  void _checkForPendingNavigation() async {
    await TakecareLinkUtil.handleDeepLinkInApp(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(activeDeviceProvider);
    final bool isOwner = device?.primaryUser ?? false;
    final bool hasDevice = device != null;
    final availableTabTypes = _getAvailableTabs(isOwner, hasDevice);

    if (!availableTabTypes.contains(_currentTab)) {
      _currentTab = TabType.home;
    }

    final currentIndex = _getTabIndex(_currentTab, isOwner, hasDevice);

    // Listen to deep link changes
    ref.listen(deepLinkProvider, (previous, next) {
       TakecareLinkUtil.handleDeepLinkInApp(context, ref);
    });

    return Scaffold(
      body: Stack(
        children: [
          _getTabWidget(_currentTab),
          Positioned(
            left: 20.w,
            right: 20.w,
            bottom: 24.h,
            child: CustomTabBar(
              currentIndex: currentIndex,
              onTabSelected: (int index) {
                setState(() {
                  _currentTab = availableTabTypes[index];
                });
              },
              tabs: availableTabTypes.map((tab) {
                switch (tab) {
                  case TabType.home:
                    return Expanded(
                      child: CustomTabBarItem(
                        icon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/house-outline.svg',
                          height: 24.h,
                        ),
                        selectedIcon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/house-filled.svg',
                          height: 24.h,
                        ),
                        label: AppLocalizations.of(context)!.tabHome,
                        isSelected: _currentTab == TabType.home,
                        onTap: () {
                          setState(() {
                            _currentTab = TabType.home;
                          });
                        },
                      ),
                    );
                  case TabType.pills:
                    return Expanded(
                      child: CustomTabBarItem(
                        icon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/pill-outline.svg',
                          height: 24.h,
                        ),
                        selectedIcon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/pill-filled.svg',
                          height: 24.h,
                        ),
                        label: AppLocalizations.of(context)!.tabPills,
                        isSelected: _currentTab == TabType.pills,
                        onTap: () {
                          setState(() {
                            _currentTab = TabType.pills;
                          });
                        },
                      ),
                    );
                  case TabType.devices:
                    return Expanded(
                      child: CustomTabBarItem(
                        icon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/settings-outline.svg',
                          height: 24.h,
                        ),
                        selectedIcon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/settings-filled.svg',
                          height: 24.h,
                        ),
                        label: AppLocalizations.of(context)!.tabSettings,
                        isSelected: _currentTab == TabType.devices,
                        onTap: () {
                          setState(() {
                            _currentTab = TabType.devices;
                          });
                        },
                      ),
                    );
                  case TabType.account:
                    return Expanded(
                      child: CustomTabBarItem(
                        icon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/user-outline.svg',
                          height: 24.h,
                        ),
                        selectedIcon: SvgPicture.asset(
                          'lib/assets/SVG/tabs/user-filled.svg',
                          height: 24.h,
                        ),
                        label: AppLocalizations.of(context)!.tabAccount,
                        isSelected: _currentTab == TabType.account,
                        onTap: () {
                          setState(() {
                            _currentTab = TabType.account;
                          });
                        },
                      ),
                    );
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
