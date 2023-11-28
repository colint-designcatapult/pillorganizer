import 'package:app/provider/provision_provider.dart';
import 'package:app/screens/provisioning/wifi_select_screen.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../api/provision.dart';

class ErrorInfoBox extends StatefulWidget {
  const ErrorInfoBox({super.key, required this.error});

  final Object? error;

  @override
  State<StatefulWidget> createState() => _ErrorInfoBoxState();
}

class _ErrorInfoBoxState extends State<ErrorInfoBox> {
  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      shrinkWrap: true,
      data: AppLocalizations.of(context)!
          .genericErrorInfoText(widget.error?.toString() ?? ''),
    );
  }
}

class ProvisionPage extends StatefulWidget {
  const ProvisionPage({super.key});

  static Route<ProvisionPage> route(context) => platformPageRoute(
      context: context, builder: (_) => const ProvisionPage());

  @override
  State<StatefulWidget> createState() => _ProvisionPageState();
}

class _ProvisionPageState extends State<ProvisionPage>
    with TickerProviderStateMixin {
  bool scanningWifi = false;
  bool timeoutTryAgain = false;

  @override
  void initState() {
    super.initState();
    _startScanningBluetooth();
  }

  void _startScanningBluetooth() {
    final prov = Provider.of<ProvisionProvider>(context, listen: false);

    if (prov.state.deviceName == null) {
      prov.scanBluetooth().then((state) {
        if (state.deviceName != null && context.mounted) {
          Navigator.of(context)
              .pushReplacement(ProvisionSelectWifiPage.route(context, state));
        }
      }).timeout(const Duration(seconds: 25), onTimeout: () {
        timeoutTryAgain = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(1, 1);
    return Selector<ProvisionProvider,
            Tuple3<ProvisionStage, Object?, double?>>(
        selector: (_, prov) =>
            Tuple3(prov.state.stage, prov.state.error, prov.state.progress),
        builder: (_, data, __) {
          return WizardStep(
            height: data.item2 != null
                ? null
                : data.item1 == ProvisionStage.select_ble
                    ? 600
                    : 400,
            provisionningProgress: provisionningProgress,
            title: _buildTitle(data),
            subtext: _buildSubtitle(data),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            footer: data.item2 != null || timeoutTryAgain
                ? PlatformElevatedButton(
                    child: Text(AppLocalizations.of(context)!.genericTryAgain),
                    onPressed: () {
                      timeoutTryAgain = false;
                      Provider.of<ProvisionProvider>(context, listen: false)
                          .rescanBluetooth()
                          .then((state) {
                        if (state.deviceName != null && context.mounted) {
                          Navigator.of(context).pushReplacement(
                              ProvisionSelectWifiPage.route(context, state));
                        }
                      }).timeout(const Duration(seconds: 25), onTimeout: () {
                        timeoutTryAgain = true;
                      });
                    },
                  )
                : null,
            child: _buildBody(
                data, Provider.of<ProvisionProvider>(context, listen: true)),
          );
        });
  }

  Widget _buildBody(
      Tuple3<ProvisionStage, Object?, double?> data, ProvisionProvider prov) {
    if (data.item2 != null) {
      return Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: data.item2),
              )));
    } else if (data.item1 == ProvisionStage.scanning_ble) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(32)),
                child: LinearProgressIndicator(
                  value: data.item3,
                  semanticsLabel: AppLocalizations.of(context)!.progress,
                  minHeight: 12,
                )),
          ));
    } else if (data.item1 == ProvisionStage.select_ble && !scanningWifi) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ...prov.state.bluetoothList!
                    .map((e) => _buildBleCard(context, e, prov))
                    .toList(growable: false),
                TextButton(
                  onPressed: () {
                    prov.rescanBluetooth();
                  },
                  child:
                      Text(AppLocalizations.of(context)!.provRescanBluetooth),
                ),
                const SizedBox(
                  height: 35,
                )
              ],
            )),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildBleCard(context, String entry, ProvisionProvider prov) {
    Widget? subtitle;

    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(entry),
            subtitle: subtitle,
            onTap: () {
              setState(() {
                scanningWifi = true;
              });
              prov.selectBluetooth(entry).then((state) {
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                      ProvisionSelectWifiPage.route(context, state));
                }
              });
            },
          ),
        ));
  }

  String _buildTitle(data) {
    if (data.item2 != null) {
      return AppLocalizations.of(context)!.provErrConGeneric;
    } else if (data.item1 == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearching;
    } else if (data.item1 == ProvisionStage.scanning_wifi || scanningWifi) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else if (data.item1 == ProvisionStage.select_ble) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String _buildSubtitle(data) {
    if (data.item2 != null) {
      return AppLocalizations.of(context)!.provErrConGenericSubtitle;
    } else if (data.item1 == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearchingSubtitle;
    } else if (data.item1 == ProvisionStage.scanning_wifi || scanningWifi) {
      return AppLocalizations.of(context)!.provConConnectingSubtitle;
    } else if (data.item1 == ProvisionStage.select_ble) {
      return AppLocalizations.of(context)!.provConSelectingSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }
}
