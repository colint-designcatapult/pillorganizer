import 'dart:async';

import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../api/provision.dart';
import '../../provider/provision_provider.dart';
import '../../widgets/wizard.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'connecting_screen.dart';

class ProvisionSelectWifiPage extends StatelessWidget {
  const ProvisionSelectWifiPage({super.key});

  static Route<ProvisionSelectWifiPage> route(context, state) =>
      platformPageRoute(
          context: context, builder: (_) => const ProvisionSelectWifiPage());

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(1, 2);
    return ScreenUtilWrapper(
      child: WizardStep(
        provisionningProgress: provisionningProgress,
        title: AppLocalizations.of(context)!.provSelectWifi,
        subtext: AppLocalizations.of(context)!.provSelectWifiSubtitle,
        onBackPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.0.w, bottom: 32.0.h),
            child: Consumer<ProvisionProvider>(
              builder: (_, prov, child) {
                if (prov.state.wifiNetworks == null) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ...prov.state.wifiNetworks!
                            .map((e) => _buildWifiCard(context, e, prov))
                            .toList(growable: false),
                        TextButton(
                          onPressed: () {
                            prov.rescanNetworks();
                          },
                          child: Text(
                              AppLocalizations.of(context)!.provRescanWifi),
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
      ),
    );
  }

  void _showPasswordDialog(
      BuildContext context, WifiEntry entry, ProvisionProvider prov) {
    if (prov.state.stage == ProvisionStage.select_wifi) {
      PasswordEntryModal.show(context, entry).then((value) {
        if (value != null) {
          prov.setWifiPassword(context, entry.name, value).then((value) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                  ProvisionConnectingPage.route(context, value));
            }
          });
        }
      });
    }
  }

  Widget _buildWifiCard(context, WifiEntry entry, ProvisionProvider prov) {
    Widget? subtitle;

    if (prov.state.ssid == entry.name) {
      if (prov.state.error != null) {
        String text;
        if (prov.state.error is TimeoutException) {
          text = AppLocalizations.of(context)!.genericTryAgain;
        } else {
          text = provErrorMessage(context, prov.state.error.toString());
        }
        subtitle = Text(
          text,
          style: TextStyle(color: Theme.of(context).errorColor),
        );
      }
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Card(
          elevation: 1,
          child: ListTile(
            leading: prov.state.ssid == entry.name && prov.state.error == null
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(),
                  )
                : Icon(_wifiIcon(entry)),
            title: Text(entry.name),
            subtitle: subtitle,
            onTap: () {
              _showPasswordDialog(context, entry, prov);
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

class PasswordEntryModal extends StatefulWidget {
  const PasswordEntryModal({super.key, required this.wifiEntry});

  final WifiEntry wifiEntry;

  static Future<String?> show(context, WifiEntry entry) {
    return showPlatformDialog(
        context: context,
        builder: (context) {
          return PasswordEntryModal(wifiEntry: entry);
        });
  }

  @override
  State<StatefulWidget> createState() => _PasswordEntryModal();
}

class _PasswordEntryModal extends State<PasswordEntryModal> {
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: PlatformAlertDialog(
          title: Text(AppLocalizations.of(context)!
              .provEnterWifiPassword(widget.wifiEntry.name)),
          content: PlatformTextFormField(
            obscureText: true,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onEditingComplete: _submit,
            onSaved: _value,
            cupertino: (_, __) => CupertinoTextFormFieldData(),
          ),
          actions: [
            PlatformDialogAction(
              child: Text(AppLocalizations.of(context)!.genericCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            PlatformDialogAction(
              child: Text(AppLocalizations.of(context)!.genericOK),
              onPressed: () {
                _submit();
              },
            ),
          ]),
    );
  }

  void _value(String? val) {
    Navigator.of(context).pop(val);
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
    }
  }
}
