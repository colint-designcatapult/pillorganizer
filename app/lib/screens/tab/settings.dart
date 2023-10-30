import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/button_icon_text.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/device_rename_modal.dart';
import '../../widgets/schedule_entry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

void changeName(context) {
  showDialog(
    context: context,
    builder: (_) => const ChangeDeviceNameDialog(),
  );
}

void deleteDevice(context) {
  showDialog(
    context: context,
    builder: (_) => const RemoveDeviceDialog(),
  );
}

class _SettingsScreenState extends State<SettingsScreen> {
  int selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFBFD2DB),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 75.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                      child: Text(
                        prov.device!.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 24.0, bottom: 32.0),
                      child: Row(
                        children: [
                          ButtonIconText(
                              text: AppLocalizations.of(context)!.changeName,
                              iconData: PhosphorIcons.pencil_simple,
                              onPressed: () {
                                changeName(context);
                              }),
                          const SizedBox(width: 20.0),
                          ButtonIconText(
                              text: AppLocalizations.of(context)!.delete,
                              iconData: PhosphorIcons.trash_simple,
                              onPressed: () {
                                deleteDevice(context);
                              }),
                        ],
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 12,
                                  left: 20,
                                  right: 20,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SegmentedButton(
                                        segments: <ButtonSegment>[
                                          ButtonSegment(
                                              icon: const Icon(
                                                  PhosphorIcons.timer),
                                              value: 0,
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .timeSettings,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500),
                                              )),
                                          ButtonSegment(
                                            icon: const Icon(PhosphorIcons
                                                .bell_simple_ringing),
                                            value: 1,
                                            label: Text(
                                              AppLocalizations.of(context)!
                                                  .notifications,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                        selected: {selectedButtonIndex},
                                        selectedIcon: selectedButtonIndex == 0
                                            ? const Icon(PhosphorIcons.timer)
                                            : const Icon(PhosphorIcons
                                                .bell_simple_ringing),
                                        onSelectionChanged: (Set newSelection) {
                                          setState(() {
                                            selectedButtonIndex =
                                                newSelection.first;
                                          });
                                        },
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadiusDirectional
                                                          .circular(8))),
                                          side: MaterialStateProperty
                                              .resolveWith<BorderSide>(
                                                  (Set<MaterialState> states) {
                                            return const BorderSide(
                                                color: Color(0xFFBFD2DB),
                                                width: 2.0);
                                          }),
                                          backgroundColor: MaterialStateProperty
                                              .resolveWith<Color>(
                                                  (Set<MaterialState> states) {
                                            if (states.contains(
                                                MaterialState.selected)) {
                                              return const Color(0xFFE8EFF4);
                                            }
                                            return Colors.white;
                                          }),
                                          padding: MaterialStateProperty.all<
                                              EdgeInsetsGeometry>(
                                            const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: selectedButtonIndex == 0
                                          ? const ScheduleEntry()
                                          : const NotificationsSettings()),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationsSettings extends StatelessWidget {
  const NotificationsSettings({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    void toggleNotifications() {
      var sdp = Provider.of<SelectedDeviceProvider>(context, listen: false);
      sdp.updateNotifications(!(sdp.device?.notifications ?? false));
    }

    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.notificationPreferences,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Switch(
                value: Provider.of<SelectedDeviceProvider>(context)
                        .device
                        ?.notifications ??
                    false,
                onChanged: (bool value) {
                  toggleNotifications();
                },
                activeTrackColor: const Color(0xff708F72),
                thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Icon(Icons.check, color: Color(0xff708F72));
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.notificationReminder,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ]);
  }
}
