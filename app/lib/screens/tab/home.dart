import 'package:app/provider/time_provider.dart';
import 'package:app/widgets/device_info_header.dart';
import 'package:app/widgets/device_alert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    return BLEAutoSuppress(
        child: AutoRefresh(
      refreshable: Provider.of<DeviceStateProvider>(context),
      refreshInterval: const Duration(seconds: 3),
      child: Consumer<DeviceNoticeProvider>(
        builder: (context, deviceNoticeProvider, child) {
          final bool hasNotice =
              deviceNoticeProvider.value != DeviceNotice.none;
          return Scaffold(
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
                      expandedHeight: MediaQuery.of(context).size.height *
                          (hasNotice ? 0.25 : 0.150),
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        expandedTitleScale: 1.0,
                        titlePadding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 00.0),
                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: DeviceInfoHeader(),
                            ),
                            if (hasNotice)
                              DeviceAlert(
                                notice: deviceNoticeProvider.value,
                                onReload: () => deviceNoticeProvider.reload(),
                                reloadFuture: () =>
                                    deviceNoticeProvider.reloadFuture,
                              ),
                          ],
                        ),
                      ),
                      pinned: false,
                    ),
                  ];
                },
                body: ClipRRect(
                  borderRadius:
                      const BorderRadius.only(topRight: Radius.circular(40.0)),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(40.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 24.0, left: 24.0, right: 24.0, bottom: 74),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Consumer<MinuteBasedTimeProvider>(
                                builder: (context, minuteProvider, child) {
                                  return Text(
                                    AppLocalizations.of(context)!.localeName ==
                                            'fr'
                                        ? DateFormat('EEEE, d MMMM', 'fr')
                                            .format(minuteProvider.value)
                                        : DateFormat('EEEE, d MMMM', 'en')
                                            .format(minuteProvider.value),
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: Pillbox()),
                          const DosePeriodArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    ));
  }
}
