import 'package:app/navigation/tab_bar.dart';
import 'package:app/navigation/tab_bar_item.dart';
import 'package:app/screens/tab/home.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/tab/account.dart';
import 'package:app/screens/tab/pills_screen.dart';
import 'package:app/screens/tab/settings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../api/device.dart';
import '../provider/device_connection_status_provider.dart';
import '../provider/device_notice_provider.dart';
import '../provider/scroll_provider.dart';
import '../provider/selected_device_provider.dart';
import '../provider/time_provider.dart';

const Color backgroundColor = Color(0xFF206B8B);
const Color activeColor = Color(0xFFBFD2DB);

class TabNavigator extends StatefulWidget {
  const TabNavigator({Key? key}) : super(key: key);

  @override
  _TabNavigatorState createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    Builder(builder: (context) => const HomeScreen()),
    Builder(builder: (context) => const PillsScreen()),
    Builder(builder: (context) => const SettingsScreen()),
    Builder(builder: (context) => const AccountScreen()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      deviceRepo.deviceListProvider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            _tabs[_currentIndex],
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: CustomTabBar(
                currentIndex: _currentIndex,
                onTabSelected: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                tabs: [
                  Expanded(
                    child: CustomTabBarItem(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/house-outline.svg',
                        height: 24,
                      ),
                      selectedIcon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/house-filled.svg',
                        height: 24,
                      ),
                      label: 'Home',
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomTabBarItem(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/pill-outline.svg',
                        height: 24,
                      ),
                      selectedIcon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/pill-filled.svg',
                        height: 24,
                      ),
                      label: 'My Pills',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomTabBarItem(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/settings-outline.svg',
                        height: 24,
                      ),
                      selectedIcon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/settings-filled.svg',
                        height: 24,
                      ),
                      label: 'Settings',
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomTabBarItem(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/user-outline.svg',
                        height: 24,
                      ),
                      selectedIcon: SvgPicture.asset(
                        'lib/assets/SVG/tabs/user-filled.svg',
                        height: 24,
                      ),
                      label: 'Account',
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
