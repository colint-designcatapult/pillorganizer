import 'package:app/api/api.dart';
import 'package:app/provider/scroll_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../api/device.dart';

import '../../platform/ble_auto_supress.dart';
import '../../provider/device_connection_status_provider.dart';
import '../../provider/device_notice_provider.dart';
import '../../provider/selected_device_provider.dart';
import '../../provider/time_provider.dart';
import '../../widgets/dose_period_area.dart';

import '../../widgets/pillbox/pill_box.dart';
import '../modals/edit_schedule_modal.dart';
import '../my_account/my_account.dart';

const double sidePadQ = 22.0;
const EdgeInsets sidePad = EdgeInsets.symmetric(horizontal: sidePadQ);

class IndexAppBar extends StatelessWidget {
  IndexAppBar({super.key});

  final textStyle =
      const TextStyle(fontWeight: FontWeight.w200, fontFamily: 'RobotoSlab');
  final dayOfWeekFormat = DateFormat.EEEE();
  final subtitleFormat = DateFormat.yMMMMd();
  String _title(MinuteBasedTimeProvider prov) {
    return dayOfWeekFormat.format(prov.value);
  }

  String _subtitle(MinuteBasedTimeProvider prov) {
    return subtitleFormat.format(prov.value);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 160.0,
      collapsedHeight: 100.0,
      flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(
              left: sidePadQ, bottom: sidePadQ, right: sidePadQ),
          collapseMode: CollapseMode.parallax,
          title: Consumer<MinuteBasedTimeProvider>(
            builder: (_, prov, __) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(_title(prov),
                          style: textStyle.copyWith(fontSize: 32)),
                      Text(_subtitle(prov),
                          style: textStyle.copyWith(fontSize: 16))
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle),
                    onPressed: () {
                      Navigator.of(context).push(MyAccountPage.route(context));
                    },
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  )
                ],
              );
            },
          )),
    );
  }
}

class DeviceSettingsItem extends StatelessWidget {
  final void Function(BuildContext) onSelected;
  final String title;
  final Widget? icon;
  final bool warning;
  const DeviceSettingsItem(
      {super.key,
      required this.onSelected,
      required this.title,
      this.icon,
      this.warning = false});

  @override
  Widget build(BuildContext context) {
    Color? color = warning ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Text(title, style: TextStyle(inherit: true, color: color)),
        const Spacer(),
        if (icon != null) icon!,
      ],
    );
  }
}

void editSchedule(context) {
  showEditScheduleModal(context);
}

class CircularBinStatusIndicator extends StatelessWidget {
  final BinStatus status;
  final DeviceNotice deviceStatus;
  const CircularBinStatusIndicator(
      {super.key, required this.status, required this.deviceStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color border;

    switch (status) {
      case BinStatus.TAKEN:
      case BinStatus.TAKE_NOW:
        color = const Color(0xFF7CAC7B);
        border = const Color(0xFF4D7B50);
        break;
      case BinStatus.MISSED:
        color = const Color(0xFFD45C5C);
        border = const Color(0xFF7A2C2C);
        break;
      default:
        color = const Color(0xFF798290);
        border = const Color(0xFF434747);
    }

    return Container(
      height: 20,
      width: 20,
      decoration:
          status != BinStatus.DISABLED && deviceStatus != DeviceNotice.empty
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: border, width: 3),
                )
              : null,
      child: Visibility(
          visible: status == BinStatus.DISABLED ||
              deviceStatus == DeviceNotice.empty,
          child: SvgPicture.asset(
            'lib/assets/SVG/cancelIcon.svg',
            height: 20,
            width: 20,
          )),
    );
  }
}

class DeviceNoticeArea extends StatelessWidget {
  const DeviceNoticeArea({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<DeviceNoticeProvider>(
        builder: (context, prov, _) {
          if (prov.value != DeviceNotice.none) {
            return Padding(
              padding: sidePad,
              child: _buildNotice(context, prov.value, prov),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget _buildNotice(context, DeviceNotice notice, DeviceNoticeProvider prov) {
    if (notice == DeviceNotice.disconnected) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: const Icon(Icons.warning),
          title: Text(AppLocalizations.of(context)!.noticeDisconnected),
          subtitle:
              Text(AppLocalizations.of(context)!.noticeDisconnectedSubtitle),
        ),
      );
    } else if (notice == DeviceNotice.empty) {
      return Card(
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: const Icon(Icons.calendar_view_week_outlined),
              title: Text(AppLocalizations.of(context)!.noticeEmpty),
              subtitle: Text(AppLocalizations.of(context)!.noticeEmptySubtitle),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: FutureBuilder(
                    future: prov.reloadFuture,
                    builder: (context, snapshot) {
                      bool loading =
                          snapshot.connectionState != ConnectionState.none;
                      return TextButton.icon(
                          onPressed: loading ? null : () => _reload(prov),
                          icon: loading
                              ? const SizedBox(
                                  child: CircularProgressIndicator(),
                                  height: 16.0,
                                  width: 16.0)
                              : const Icon(Icons.check),
                          label: Text(
                              AppLocalizations.of(context)!.noticeEmptyAction));
                    }),
              ),
            )
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  void _reload(DeviceNoticeProvider prov) {
    prov.reload();
  }
}

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  static void performPreloadLogic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      deviceRepo.deviceListProvider.refresh();
    });
  }

  static Route<IndexPage> route(context) {
    return platformPageRoute(
        context: context,
        builder: (_) {
          performPreloadLogic();
          return const IndexPage();
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
      builder: (context, _) => BLEAutoSuppress(
          child: AutoRefresh(
        refreshable: Provider.of<DeviceStateProvider>(context),
        refreshInterval: const Duration(seconds: 3),
        child: Scaffold(
            body: Container(
                color: const Color(0xFFF1F6F5),
                child: CustomScrollView(
                  controller: context.select<ScrollProvider, ScrollController>(
                      (p) => p.controller),
                  slivers: [
                    IndexAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: sidePad.copyWith(top: 16.0),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Pillbox()],
                        ),
                      ),
                    ),
                    const DeviceNoticeArea(),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 12.0,
                      ),
                    ),
                  ],
                ))),
      )),
    );
  }
}
