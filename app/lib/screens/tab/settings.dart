import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/button_icon_text.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              padding: EdgeInsets.only(top: 75.h, bottom: 20.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 24.w, bottom: 8.h),
                      child: Text(
                        prov.device?.name ??
                            AppLocalizations.of(context)!.loadingState,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 32.h,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 24.w, bottom: 32.h),
                      child: Row(
                        children: [
                          ButtonIconText(
                              text: AppLocalizations.of(context)!.changeName,
                              iconData: PhosphorIcons.pencil_simple,
                              onPressed: () {
                                changeName(context);
                              }),
                          SizedBox(width: 20.w),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0).r,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  top: 24.h,
                                  bottom: 12.h,
                                  left: 20.w,
                                  right: 20.w,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SegmentedButton(
                                        segments: <ButtonSegment>[
                                          ButtonSegment(
                                              icon: Icon(
                                                PhosphorIcons.timer,
                                                size: 18.h,
                                              ),
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
                                            icon: Icon(
                                              PhosphorIcons.bell_simple_ringing,
                                              size: 18.h,
                                            ),
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
                                            ? Icon(
                                                PhosphorIcons.timer,
                                                size: 18.h,
                                              )
                                            : Icon(
                                                PhosphorIcons
                                                    .bell_simple_ringing,
                                                size: 18.h,
                                              ),
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
                                                          .circular(8.r))),
                                          side: MaterialStateProperty
                                              .resolveWith<BorderSide>(
                                                  (Set<MaterialState> states) {
                                            return BorderSide(
                                                color: const Color(0xFFBFD2DB),
                                                width: 2.h);
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
                                            EdgeInsets.symmetric(
                                                vertical: 16.h,
                                                horizontal: 12.w),
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
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w, vertical: 20.h),
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
          SizedBox(height: 26.h),
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
              SizedBox(width: 16.w),
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
