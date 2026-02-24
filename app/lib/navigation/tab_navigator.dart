import 'package:app/navigation/tab_bar.dart';
import 'package:app/navigation/tab_bar_item.dart';
import 'package:app/provider/deep_link_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/screens/tab/account.dart';
import 'package:app/screens/tab/home.dart';
import 'package:app/screens/tab/my_devices.dart';
import 'package:app/screens/tab/pills_screen.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../provider/device_connection_status_provider.dart';
import '../provider/device_notice_provider.dart';
import '../provider/device_state_provider.dart';
import '../provider/scroll_provider.dart';
import '../provider/selected_device_provider.dart';
import '../provider/time_provider.dart';

const Color backgroundColor = Color(0xFF206B8B);
const Color activeColor = Color(0xFFBFD2DB);

enum TabType { home, pills, devices, account }

class TabNavigator extends StatefulWidget {
  const TabNavigator({Key? key}) : super(key: key);

  @override
  _TabNavigatorState createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  TabType _currentTab = TabType.home;
  DeepLinkProvider? _deepLinkProvider;

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
      Provider.of<DeviceProvider>(context, listen: false).loadDevices();
      _setupDeepLinkListener();
      _checkForPendingNavigation();
    });
  }

  void _setupDeepLinkListener() {
    _deepLinkProvider = Provider.of<DeepLinkProvider>(context, listen: false);
    _deepLinkProvider!.addListener(_onDeepLinkChange);
  }

  void _onDeepLinkChange() async {
    await TakecareLinkUtil.handleDeepLinkInApp(context);
  }

  @override
  void dispose() {
    _deepLinkProvider?.removeListener(_onDeepLinkChange);
    super.dispose();
  }

  void _checkForPendingNavigation() async {
    await TakecareLinkUtil.handleDeepLinkInApp(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(
      builder: (context, selectedDeviceProvider, child) {
        final device = selectedDeviceProvider.device;
        final bool isOwner = device?.owner ?? false;
        final bool hasDevice = device != null;
        final availableTabTypes = _getAvailableTabs(isOwner, hasDevice);

        if (!availableTabTypes.contains(_currentTab)) {
          _currentTab = TabType.home;
        }

        final currentIndex = _getTabIndex(_currentTab, isOwner, hasDevice);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ScrollProvider>(
              create: (_) => ScrollProvider(),
            ),
            ChangeNotifierProxyProvider2<MinuteBasedTimeProvider,
                SelectedDeviceProvider, DeviceStateProvider>(
              create: (_) => DeviceStateProvider(),
              update: (_, time, selected, old) =>
                  old!.update(time.value, selected.device),
            ),
            ChangeNotifierProxyProvider<DeviceStateProvider,
                DeviceConnectionStatusProvider>(
              create: (_) => DeviceConnectionStatusProvider(),
              update: (_, state, old) => old!.update(state.value),
              lazy: false,
            ),
            ChangeNotifierProxyProvider2<DeviceStateProvider,
                DeviceConnectionStatusProvider, DeviceNoticeProvider>(
              create: (_) => DeviceNoticeProvider(),
              update: (_, state, status, old) =>
                  old!.update(state.value, status.value),
            )
          ],
          child: Scaffold(
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
          ),
        );
      },
    );
  }
}
