import 'package:app/navigation/provision_navigator.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/provisioning/join_device_screen.dart';
import 'package:app/widgets/device_alert.dart';
import 'package:app/widgets/device_info_header.dart';
import 'package:app/widgets/stateful_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../api/device.dart';
import '../../platform/ble_auto_supress.dart';
import '../../provider/device_notice_provider.dart';
import '../../widgets/dose_period_area.dart';
import '../../widgets/pillbox/pill_box.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DeviceUser? device =
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;

    return StatefulWrapper(
        onInit: () {
          _askPermissions(context);
        },
        child: BLEAutoSuppress(
            child: AutoRefresh(
          refreshable: Provider.of<DeviceStateProvider>(context),
          refreshInterval: const Duration(seconds: 3),
          child: Consumer<DeviceNoticeProvider>(
            builder: (context, deviceNoticeProvider, child) {
              final bool hasNotice =
                  deviceNoticeProvider.value != DeviceNotice.none;
              return ScreenUtilWrapper(
                child: Scaffold(
                  body: Stack(children: [
                    Container(
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.3317],
                          colors: [
                            Color(0xFF206B8B),
                            Color(0xFF002D40),
                          ],
                        ),
                      ),
                    ),
                    NestedScrollView(
                      headerSliverBuilder:
                          (BuildContext context, bool innerBoxIsScrolled) {
                        return <Widget>[
                          SliverAppBar(
                            toolbarHeight: (hasNotice ? 280 : 130).h,
                            backgroundColor: Colors.transparent,
                            flexibleSpace: FlexibleSpaceBar(
                              expandedTitleScale: 1.0,
                              titlePadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              title: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24.w, vertical: 12.h),
                                    child: DeviceInfoHeader(
                                        deviceOffline:
                                            deviceNoticeProvider.value ==
                                                DeviceNotice.disconnected),
                                  ),
                                  hasNotice
                                      ? DeviceAlert(
                                          notice: deviceNoticeProvider.value,
                                          onReload: () =>
                                              deviceNoticeProvider.reload(),
                                          reloadFuture: () =>
                                              deviceNoticeProvider.reloadFuture,
                                        )
                                      : SizedBox(height: 8.h),
                                ],
                              ),
                            ),
                            pinned: false,
                          ),
                        ];
                      },
                      body: device == null
                          ? _noDeviceScreen(context)
                          : _homeBody(context, hasNotice),
                    ),
                  ]),
                ),
              );
            },
          ),
        )));
  }

  Widget _homeBody(BuildContext context, bool hasNotice) {
    return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(40.0).r,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Consumer<MinuteBasedTimeProvider>(
                    builder: (context, minuteProvider, child) {
                      return Text(
                        AppLocalizations.of(context)!.localeName == 'fr'
                            ? DateFormat('EEEE, d MMMM', 'fr')
                                .format(minuteProvider.value)
                            : DateFormat('EEEE, d MMMM', 'en')
                                .format(minuteProvider.value),
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Pillbox()),
              if (!hasNotice &&
                  Provider.of<DeviceStateProvider>(context, listen: false)
                          .value !=
                      null)
                const DosePeriodArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noDeviceScreen(BuildContext context) {
    var date = DateTime.now();

    void handleConnectNewDevice() {
      Provider.of<DeviceBluetoothProvider>(context, listen: false).suppress();
      startProvisioning(context);
    }

    void handleJoinExistingDevice() {
      Navigator.of(context).push(JoinDevicePage.route(context));
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(40.0).r,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              AppLocalizations.of(context)!.localeName == 'fr'
                  ? DateFormat('EEEE, d MMMM', 'fr').format(date)
                  : DateFormat('EEEE, d MMMM', 'en').format(date),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(AppLocalizations.of(context)!.noDeviceDescription,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            OutlinedButton(
                onPressed: () => handleConnectNewDevice(),
                style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(
                      color:
                          Color(0xff8BCAE5), // Change border color to #8BCAE5
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    backgroundColor: const Color(0xFFFFFFFF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withAlpha(127)),
                child: Text(
                  AppLocalizations.of(context)!.quickSwitchNewDevice,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Color(0xff206B8B))
                      .copyWith(fontWeight: FontWeight.w600),
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: OutlinedButton(
                  onPressed: () => handleJoinExistingDevice(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0).r,
                    ),
                    backgroundColor: const Color(0xff206B8B),
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(
                      color: Color(0xff206B8B),
                    ),
                  ),
                  child: Text(
                      AppLocalizations.of(context)!.quickSwitchExistingDevice,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                ))
          ]),
        ),
      ),
    );
  }

  Future<void> _askPermissions(BuildContext context) async {
    //Ask Notification permission
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }
}
