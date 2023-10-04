import 'package:app/api/api.dart';
import 'package:app/api/medication.dart';
import 'package:app/provider/scroll_provider.dart';
import 'package:app/screens/modals/device_selector_modal.dart';
import 'package:app/widgets/mini_device.dart';
import 'package:app/widgets/pillbox/bin_container.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../api/device.dart';
import '../main.dart';
import '../provider/device_connection_status_provider.dart';
import '../provider/device_notice_provider.dart';
import '../provider/medication_provider.dart';
import '../provider/selected_device_provider.dart';
import '../provider/time_provider.dart';
import '../widgets/device_icon.dart';
import '../widgets/medication_icon.dart';
import '../widgets/time_of_day_scaffold.dart';
import 'device_settings/medication/medication_entry_wizard.dart';
import '../widgets/pillbox/pill_box.dart';
import 'modals/edit_schedule_modal.dart';
import 'my_account/my_account.dart';

const double sidePadQ = 22.0;
const EdgeInsets sidePad = EdgeInsets.symmetric(horizontal: sidePadQ);

class BLEAutoSuppress extends StatefulWidget {
  const BLEAutoSuppress({super.key, required this.child});

  final Widget child;

  @override
  State<BLEAutoSuppress> createState() => BLEAutoSuppressState();
}

// Implement RouteAware in a widget's state and subscribe it to the RouteObserver.
class BLEAutoSuppressState extends State<BLEAutoSuppress> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).suppress();
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator.
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).unsuppress();
  }

  @override
  void initState() {
    super.initState();
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).unsuppress();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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

class DeviceListSelector extends StatelessWidget {
  const DeviceListSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceListProvider>(
      builder: (_, prov, __) {
        return RefreshablePlaceholder(
          notifier: prov,
          builder: (context, _, loading) {
            if (loading) {
              return Row(
                children: [
                  Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 12.0),
                  Container(width: 120.0, height: 16.0, color: Colors.white),
                ],
              );
            } else {
              return GestureDetector(
                onTap: () {
                  showDeviceSelectorModal(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<DeviceConnectionStatusProvider>(
                      builder: (_, prov, __) {
                        return DeviceStatusIcon(
                          size: 48.0,
                          status: prov.value,
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 4.0),
                      child: Consumer<SelectedDeviceProvider>(
                          builder: (_, selectedDevice, __) {
                        return Text(
                          '${selectedDevice.device?.name}',
                          style: Theme.of(context).textTheme.displayMedium,
                        );
                      }),
                    ),
                    const Icon(Icons.expand_more)
                  ],
                ),
              );
            }
          },
        );
      },
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

class ChangeDeviceNameDialog extends StatefulWidget {
  const ChangeDeviceNameDialog({super.key});

  @override
  State<StatefulWidget> createState() => _ChangeDeviceNameDialogState();
}

class _ChangeDeviceNameDialogState extends State<ChangeDeviceNameDialog> {
  final formKey = GlobalKey<FormState>();
  bool enableOK = false;
  String? value;

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text('Enter a name'),
      content: Form(
        key: formKey,
        child: Consumer<SelectedDeviceProvider>(
          builder: (_, provider, child) {
            return PlatformTextFormField(
              textInputAction: TextInputAction.done,
              autofocus: true,
              initialValue: provider.device?.name,
              validator: Validatorless.required("Name is required"),
              onChanged: _checkForm,
              onEditingComplete: _onSubmit,
            );
          },
        ),
      ),
      actions: <Widget>[
        PlatformDialogAction(
          child: PlatformText('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        PlatformDialogAction(
          child: PlatformText('OK'),
          onPressed: enableOK ? _onSubmit : null,
        ),
      ],
    );
  }

  void _onSubmit() async {
    _save().then((value) => Navigator.of(context).pop());
  }

  Future<void> _save() async {
    if (value != null) {
      await Provider.of<SelectedDeviceProvider>(context, listen: false)
          .updateName(value!);
    }
  }

  void _checkForm(String val) {
    value = val;
    setState(() {
      enableOK = val.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    //_checkForm();
  }
}

void changeName(context) {
  showPlatformDialog<String?>(
    context: context,
    builder: (_) => const ChangeDeviceNameDialog(),
  );
}

void editSchedule(context) {
  showEditScheduleModal(context);
}

class DeviceSettings {
  static const DeviceSettingsItem rename = DeviceSettingsItem(
    onSelected: changeName,
    title: "Rename",
    icon: Icon(Icons.edit),
  );
  static const DeviceSettingsItem changeTimezone = DeviceSettingsItem(
      onSelected: editSchedule,
      title: "Edit Schedule",
      icon: Icon(Icons.alarm));
  static const DeviceSettingsItem deviceInfo = DeviceSettingsItem(
      onSelected: changeName,
      title: "Device Info",
      icon: Icon(Icons.info_outline));

  static const List<DeviceSettingsItem> choices = <DeviceSettingsItem>[
    rename,
    changeTimezone,
    //deviceInfo
  ];
}

class DeviceSettingsButton extends StatelessWidget {
  const DeviceSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DeviceSettingsItem>(
      icon: const Icon(Icons.settings),
      onSelected: (choice) {
        choice.onSelected(context);
      },
      itemBuilder: (BuildContext context) {
        return DeviceSettings.choices.map((choice) {
          return PopupMenuItem<DeviceSettingsItem>(
            value: choice,
            child: choice,
          );
        }).toList();
      },
    );
  }
}

class MiniDeviceArea extends StatelessWidget {
  const MiniDeviceArea({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshablePlaceholder(
        notifier: Provider.of<DeviceStateProvider>(context),
        preferData: true,
        builder: (context, prov, loading) {
          double opacity =
              context.watch<DeviceConnectionStatusProvider>().value ==
                      DeviceConnectionStatus.online
                  ? 1
                  : 0.3;
          if (loading) {
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.4,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 96.0),
                  child: Container(
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        color: Colors.white),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(width: 96, height: 24),
                    ),
                  ),
                )
              ],
            );
          } else {
            return Column(
              children: [
                Opacity(
                    opacity: opacity,
                    child: MiniDevice(status: prov.value!.bins)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 96.0),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16.0)),
                        border: Border.all(
                            color: Theme.of(context).highlightColor)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconTheme(
                        data: IconThemeData(color: Theme.of(context).hintColor),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi),
                            Icon(Icons.bluetooth_disabled),
                            Icon(Icons.battery_unknown)
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          }
        });
  }
}

class DosePeriodMedication extends StatelessWidget {
  final DosePeriod period;
  final ScheduledMedication? medication;
  const DosePeriodMedication(
      {super.key, required this.medication, required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (medication != null) ...[
            MedicationIcon.fromMed(medication!, 32.0),
            Text('${medication!.name}')
          ]
        ],
      ),
    );
  }
}

class CircularBinStatusIndicator extends StatelessWidget {
  final BinStatus status;
  const CircularBinStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BinStatus.TAKEN:
      case BinStatus.TAKE_NOW:
        color = Colors.green;
        break;
      case BinStatus.MISSED:
        color = Colors.red;
        break;
      default:
        color = Theme.of(context).hintColor;
    }
    bool filled = (status == BinStatus.TAKEN || status == BinStatus.MISSED);
    return Container(
      height: 16.0,
      width: 16.0,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 4.0)),
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
          contentPadding: EdgeInsets.all(16.0),
          leading: Icon(Icons.warning),
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
              contentPadding: EdgeInsets.all(16.0),
              leading: Icon(Icons.calendar_view_week_outlined),
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
                              : Icon(Icons.check),
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

class DosePeriodArea extends StatelessWidget {
  const DosePeriodArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceStateProvider, List<DosePeriod>?>(
      selector: (_, prov) => prov.value?.dosePeriods,
      builder: (_, list, __) {
        return SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return _buildPanel(context, list?[index]);
          },
          itemCount: list?.length ?? 0,
        );
      },
    );
  }

  Widget _buildPanel(context, DosePeriod? period) {
    Color? color = Theme.of(context).indicatorColor;
    var medProv = Provider.of<MedicationsProvider>(context);
    return Padding(
      padding: sidePad.copyWith(top: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BinIcon.forBin(bin: period!.binID, color: color),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _buildTimeString(context, period),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          if (period.medicationIDs.isNotEmpty) ...[
            ...period.medicationIDs
                .map((e) => _buildMed(context, period, medProv.byID(e)))
                .toList(growable: false),
          ] else ...[
            Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(AppLocalizations.of(context)!.noticeNoMeds),
            )
          ],
          TextButton.icon(
              icon: Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.actionAddMed),
              onPressed: () {
                Navigator.of(context)
                    .push(NewMedicationWizardPage.route(
                        context,
                        Provider.of<SelectedDeviceProvider>(context,
                                listen: false)
                            .device!
                            .deviceID))
                    .then((value) {
                  Provider.of<MedicationsProvider>(context, listen: false)
                      .refresh();
                });
              })
        ],
      ),
    );
  }

  Widget _buildMed(context, DosePeriod period, ScheduledMedication? med) {
    if (med != null) {
      return Card(
        child: ListTile(
          leading: MedicationIcon.fromMed(med, 32.0),
          title: Text('${med.name}'),
          subtitle: Text(_buildSubtitle(context, period)),
          trailing: CircularBinStatusIndicator(status: period.status),
          onTap: () {
            Navigator.of(context)
                .push(EditMedicationWizardPage.route(
                    context,
                    med,
                    Provider.of<SelectedDeviceProvider>(context, listen: false)
                        .device!
                        .deviceID))
                .then((value) {
              Provider.of<MedicationsProvider>(context, listen: false)
                  .refresh();
            });
          },
        ),
      );
    } else {
      return Card(
        child: ShimmerPlaceholder(
          loading: true,
          builder: (BuildContext context, bool loading) {
            return ListTile(
              leading: Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                height: 32.0,
                width: 32.0,
              ),
              title: Container(width: 120.0, height: 32.0, color: Colors.white),
            );
          },
        ),
      );
    }
  }

  String _buildSubtitle(context, DosePeriod period) {
    final fm = DateFormat.jm();
    if (period.scheduledTime == null) {
      return "";
    }
    String format = fm.format(period.scheduledTime!);

    if (period.status == BinStatus.PENDING) {
      return AppLocalizations.of(context)!.doseTakeAt(format);
    } else if (period.status == BinStatus.TAKEN) {
      return AppLocalizations.of(context)!.doseTakenAt(format);
    } else if (period.status == BinStatus.TAKE_NOW) {
      return AppLocalizations.of(context)!.doseTakeNow;
    } else {
      return '';
    }
  }

  String _buildTimeString(context, DosePeriod period) {
    final fm = DateFormat.jm();
    if (period.scheduledTime != null) {
      return AppLocalizations.of(context)!
          .doseTodayAt(fm.format(period.scheduledTime!));
    } else {
      return AppLocalizations.of(context)!.genericToday;
    }
  }
}

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  static Route<IndexPage> route(context) {
    return platformPageRoute(
        context: context,
        builder: (_) {
          // Prompt initial data load here
          WidgetsBinding.instance.addPostFrameCallback((_) {
            deviceRepo.deviceListProvider.refresh();
          });

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
        child: TimeOfDayScaffold(
            child: CustomScrollView(
          controller: context
              .select<ScrollProvider, ScrollController>((p) => p.controller),
          slivers: [
            IndexAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: sidePad.copyWith(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          DeviceListSelector(),
                          Spacer(),
                          DeviceSettingsButton()
                        ],
                      ),
                    ),
                    Pillbox()
                  ],
                ),
              ),
            ),
            DeviceNoticeArea(),
            DosePeriodArea(),
          ],
        )),
      )),
    );
  }
}
