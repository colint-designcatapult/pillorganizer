import 'dart:async';

import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/provider/provision_provider.dart';
import 'package:app/widgets/missing_permission_info_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/provisioning_service.dart';
import '../../widgets/wizard.dart';
import 'package:app/l10n/app_localizations.dart';

import 'connecting_screen.dart';
import 'provision.dart';

class ProvisionSelectWifiPage extends ConsumerWidget {
  const ProvisionSelectWifiPage({super.key});

  static Route<ProvisionSelectWifiPage> route(context, state) =>
      MaterialPageRoute(
          builder: (_) => const ProvisionSelectWifiPage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provisionProvider);
    bool timeoutTryAgain = false;
    ProvisionningProgress provisionningProgress = ProvisionningProgress(2, 3);

    return ScreenUtilWrapper(
        child: WizardStep(
          provisionningProgress: provisionningProgress,
          title: AppLocalizations.of(context)!.provSelectWifi,
          subtext: state.stage == ProvisionStage.missingPermissions
              ? null
              : AppLocalizations.of(context)!.provSelectWifiSubtitle,
          onBackPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.0.w, bottom: 32.0.h),
              child: Builder(
                builder: (context) {
                  if (state.stage == ProvisionStage.missingPermissions) {
                    return Center(
                        child: Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 20.0.w),
                            child: Column(children: [
                              const SingleChildScrollView(
                                physics: AlwaysScrollableScrollPhysics(),
                                child: MissingPermissionInfoBox(),
                              ),
                              TextButton(
                                onPressed: () {
                                  timeoutTryAgain = false;
                                  ref.read(provisionProvider.notifier)
                                      .rescanNetworks()
                                      .timeout(
                                      const Duration(seconds: 25),
                                      onTimeout: () {
                                        timeoutTryAgain = true;
                                      });
                                },
                                child: Text(AppLocalizations.of(context)!
                                    .provRescanWifi),
                              ),
                            ])));
                  }
                  if (state.stage == ProvisionStage.failed) {
                    return Center(
                        child: Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 20.0.w),
                            child: Column(children: [
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ErrorInfoBox(error: state.error),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(provisionProvider.notifier)
                                      .rescanNetworks();
                                },
                                child: Text(AppLocalizations.of(context)!
                                    .provRescanWifi),
                              ),
                            ])));
                  }
                  if (state.stage == ProvisionStage.scanning_wifi || (state.wifiNetworks.isEmpty && state.stage != ProvisionStage.select_wifi)) {
                    return Center(
                        child: Column(children: [
                          const CircularProgressIndicator(),
                          timeoutTryAgain
                              ? TextButton(
                            onPressed: () {
                              timeoutTryAgain = false;
                              ref.read(provisionProvider.notifier)
                                  .rescanNetworks()
                                  .timeout(const Duration(seconds: 25),
                                  onTimeout: () {
                                    timeoutTryAgain = true;
                                  });
                            },
                            child: Text(AppLocalizations.of(context)!
                                .provRescanWifi),
                          )
                              : const SizedBox.shrink()
                        ]));
                  } else {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ...state.wifiNetworks
                              .map(
                                  (e) => _buildWifiCard(context, e, ref))
                              .toList(growable: false),
                          TextButton(
                            onPressed: () {
                              ref.read(provisionProvider.notifier).rescanNetworks();
                            },
                            child: Text(AppLocalizations.of(context)!
                                .provRescanWifi),
                          ),
                          SizedBox(
                            height: 35.h,
                          )
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ));
  }

  void _showPasswordDialog(
      BuildContext context, WifiEntry entry, WidgetRef ref) {
    final state = ref.read(provisionProvider);
    if (state.stage == ProvisionStage.select_wifi) {
      PasswordEntryModal.show(context, entry, ref).then((value) {
        if (value != null) {
          ref.read(provisionProvider.notifier).setWifiCredentials(entry.name, value);
          final newState = ref.read(provisionProvider);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
                ProvisionConnectingPage.route(context, newState));
          }
        }
      });
    }
  }

  Widget _buildWifiCard(context, WifiEntry entry, WidgetRef ref) {
    final state = ref.watch(provisionProvider);
    Widget? subtitle;

    if (state.ssid == entry.name) {
      if (state.error != null) {
        String text;
        if (state.error is TimeoutException) {
          text = AppLocalizations.of(context)!.genericTryAgain;
        } else {
          text = provErrorMessage(context, state.error.toString());
        }
        subtitle = Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      }
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Card(
          elevation: 1,
          child: ListTile(
            leading: state.ssid == entry.name && state.error == null
                ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(),
            )
                : Icon(_wifiIcon(entry)),
            title: Text(entry.name),
            subtitle: subtitle,
            onTap: () {
              _showPasswordDialog(context, entry, ref);
            },
          ),
        ));
  }

  IconData _wifiIcon(WifiEntry entry) {
    if ((entry.rssi ?? 0) > -55) {
      return Icons.wifi;
    } else if ((entry.rssi ?? 0) > -77) {
      return Icons.wifi_2_bar;
    }
    return Icons.wifi_1_bar;
  }
}

class PasswordEntryModal extends ConsumerStatefulWidget {
  const PasswordEntryModal({super.key, required this.wifiEntry});

  final WifiEntry wifiEntry;

  static Future<String?> show(context, WifiEntry entry, WidgetRef ref) {
    return showDialog<String>(
        context: context,
        builder: (context) {
          return PasswordEntryModal(wifiEntry: entry);
        });
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _PasswordEntryModal();
  }
}

class _PasswordEntryModal extends ConsumerState<PasswordEntryModal> {
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AlertDialog(
          title: Text(AppLocalizations.of(context)!
              .provEnterWifiPassword(widget.wifiEntry.name)),
          content: TextFormField(
            obscureText: true,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onEditingComplete: _submit,
            onSaved: (val) => Navigator.of(context).pop(val),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.genericCancel),
            ),
            TextButton(
              onPressed: () {
                _submit();
              },
              child: Text(AppLocalizations.of(context)!.genericOK),
            ),
          ]),
    );
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
    }
  }
}
