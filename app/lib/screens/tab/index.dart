import 'package:app/api/api.dart';
import 'package:app/api/medication.dart';
import 'package:app/provider/scroll_provider.dart';
import 'package:app/screens/modals/device_selector_modal.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../api/device.dart';

import '../../platform/ble_auto_supress.dart';
import '../../provider/device_connection_status_provider.dart';
import '../../provider/device_notice_provider.dart';
import '../../provider/medication_provider.dart';
import '../../provider/selected_device_provider.dart';
import '../../provider/time_provider.dart';
import '../../widgets/device_icon.dart';
import '../../widgets/medication_icon.dart';
import '../device_settings/medication/medication_entry_wizard.dart';
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
                          color: Color(0xFF473D3D), shape: BoxShape.circle)),
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
        List<DosePeriod>? reversedList = list?.reversed.toList();
        return SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return _buildPanel(context, reversedList?[index]);
          },
          itemCount: reversedList?.length ?? 0,
        );
      },
    );
  }

  Widget _buildPanel(context, DosePeriod? period) {
    Color? color = Theme.of(context).indicatorColor;
    var medProv = Provider.of<MedicationsProvider>(context);
    var deviceNoticeProv = Provider.of<DeviceNoticeProvider>(context);
    return Padding(
      padding: sidePad.copyWith(top: 28.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BinIcon.forBin(bin: period!.binID, color: color),
                  Text(
                    _buildTimeString(context, period),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              )),
          if (period.medicationIDs.isNotEmpty) ...[
            ...period.medicationIDs
                .map((e) => _buildMed(
                    context, period, medProv.byID(e), deviceNoticeProv))
                .toList(growable: false),
          ] else ...[
            GestureDetector(
                onTap: () => Navigator.of(context)
                        .push(NewMedicationWizardPage.route(
                            context,
                            Provider.of<SelectedDeviceProvider>(context,
                                    listen: false)
                                .device!
                                .deviceID))
                        .then((value) {
                      Provider.of<MedicationsProvider>(context, listen: false)
                          .refresh();
                    }),
                child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFF8F8FA),
                    ),
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                      dashPattern: const <double>[4, 4],
                      radius: const Radius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.addPills,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    )))
          ],
        ],
      ),
    );
  }

  Widget _buildMed(context, DosePeriod period, ScheduledMedication? med,
      DeviceNoticeProvider deviceNoticeProv) {
    if (med != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F5),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF206B8B),
                width: 2.0,
              ),
            ),
            alignment: Alignment.center,
            child: ListTile(
              leading: MedicationIcon.fromMed(med, 44.0),
              title: Text(med.name),
              subtitle: Text(_buildSubtitle(context, period, deviceNoticeProv)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                CircularBinStatusIndicator(
                    status: period.status,
                    deviceStatus: deviceNoticeProv.value),
                const SizedBox(
                  width: 10,
                ),
              ]),
              onTap: () {
                Navigator.of(context)
                    .push(EditMedicationWizardPage.route(
                        context,
                        med,
                        Provider.of<SelectedDeviceProvider>(context,
                                listen: false)
                            .device!
                            .deviceID))
                    .then((value) {
                  Provider.of<MedicationsProvider>(context, listen: false)
                      .refresh();
                });
              },
            )),
      );
    } else {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 80,
            child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F5),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFF206B8B),
                    width: 2.0,
                  ),
                ),
                alignment: Alignment.center,
                child: ShimmerPlaceholder(
                  loading: true,
                  builder: (BuildContext context, bool loading) {
                    return ListTile(
                      leading: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        height: 44.0,
                        width: 44.0,
                      ),
                      title:
                          Container(width: 70, height: 40, color: Colors.white),
                      trailing: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        height: 20,
                        width: 20,
                      ),
                    );
                  },
                )),
          ));
    }
  }

  String _buildSubtitle(
      context, DosePeriod period, DeviceNoticeProvider deviceNoticeProv) {
    final fm = DateFormat.jm();
    if (period.scheduledTime == null) {
      return "";
    }
    String format = fm.format(period.scheduledTime!);
    if (period.status == BinStatus.DISABLED ||
        deviceNoticeProv.value == DeviceNotice.empty) {
      return AppLocalizations.of(context)!.doseRefill;
    } else if (period.status == BinStatus.TAKEN) {
      return AppLocalizations.of(context)!.doseTakenAt(format);
    } else if (period.status == BinStatus.TAKE_NOW) {
      return AppLocalizations.of(context)!.doseTakeNow;
    } else if (period.status == BinStatus.PENDING) {
      return AppLocalizations.of(context)!.doseTakeAt;
    } else if (period.status == BinStatus.MISSED) {
      return AppLocalizations.of(context)!.missedAt(format);
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
        child: Container(
            color: const Color(0xFFF1F6F5),
            child: CustomScrollView(
              controller: context.select<ScrollProvider, ScrollController>(
                  (p) => p.controller),
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
                const DeviceNoticeArea(),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 12.0,
                  ),
                ),
                const DosePeriodArea(),
              ],
            )),
      )),
    );
  }
}
