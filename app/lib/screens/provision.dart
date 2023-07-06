import 'dart:async';

import 'package:app/api/device.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../api/provision.dart';

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
      data: '### Troubleshooting Tips\nWe\'re sorry you are having trouble '
          'setting up your pill organizer. Try the following troubleshooting '
          'tips and try again:\n- All lights on the pill organizer should be '
          '*flashing green*. If your organizer is not flashing green, press and'
          ' hold the **reset button** for 3 seconds (see manual for details).\n'
          '- If your organizer is still not flashing green, ensure the included '
          'power cable is properly plugged in. If it is already plugged in, try '
          'unplugging it and plugging it back in.\n- If your phone asks you if '
          'you\'d like to pair to a device, accept.\n- If your phone prompts '
          'you for permission to access Bluetooth or your location, accept.'
          '\n\n**Error Details**\n\n*${widget.error?.toString()}*',
    );
  }

}

class ProvisionPage extends StatefulWidget {
  const ProvisionPage({super.key, required this.initialState});

  final ProvisionState? initialState;

  static Route<ProvisionPage> route(context, {initialState}) =>
      platformPageRoute(context: context, builder:
          (_) => ProvisionPage(initialState: initialState));

  @override
  State<StatefulWidget> createState() => _ProvisionPageState();

}

class _ProvisionPageState extends State<ProvisionPage>
    with TickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProvisionProvider>(
      create: (context) {
        final prov = ProvisionProvider(initialState: widget.initialState);
        if(widget.initialState == null) {
          _startProvisioning(context, prov);
        }
        return prov;
      },
      builder: (context, child) {
        return Scaffold(
          body: Selector<ProvisionProvider, Tuple3<ProvisionStage, Object?, double?>>(
              selector: (_, prov) => Tuple3(prov.state.stage, prov.state.error,
                  prov.state.progress),
              builder: (_, data, __) {
                return WizardStep(
                  icon: _buildIcon(data),
                  title: _buildTitle(data),
                  subtext: _buildSubtitle(data),
                  footer: data.item2 != null ? PlatformElevatedButton(
                    child: Text(AppLocalizations.of(context)!.genericTryAgain),
                    onPressed: () {
                      _startProvisioning(context, Provider
                          .of<ProvisionProvider>(context, listen: false));
                    },
                  ) : null,
                  child: _buildBody(data),
                );
              }
          ),
        );
      },
    );
  }

  Widget _buildBody(data) {
    if(data.item2 != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: ErrorInfoBox(error: data.item2),
        )
      );
    } else {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: data.item3,
                  semanticsLabel: 'Progress',
                ),
              )
          )
      );
    }
  }

  void _startProvisioning(context, prov) {
    prov.startProvisioning().then((state) {
      if(state.error == null && context.mounted) {
        Navigator.of(context).pushReplacement(
            ProvisionSelectWifiPage.route(context, state));
      }
    });
  }

  Widget _buildIcon(data) {
    if(data.item2 != null) {
      return Icon(Icons.close, color: Theme.of(context).errorColor);
    } else if(data.item1 == ProvisionStage.scanning_ble) {
      return const Icon(Icons.phonelink_ring);
    } else if(data.item1 == ProvisionStage.scanning_wifi) {
      return const Icon(Icons.bluetooth_searching);
    } else {
      return const Icon(Icons.question_mark);
    }
  }

  String _buildTitle(data) {
    if(data.item2 != null) {
      return AppLocalizations.of(context)!.provErrConGeneric;
    } else if(data.item1 == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearching;
    } else if(data.item1 == ProvisionStage.scanning_wifi) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String _buildSubtitle(data) {
    if(data.item2 != null) {
      return AppLocalizations.of(context)!.provErrConGenericSubtitle;
    } else if(data.item1 == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearchingSubtitle;
    } else if(data.item1 == ProvisionStage.scanning_wifi) {
      return AppLocalizations.of(context)!.provConConnectingSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  @override
  void initState() {
    super.initState();
  }



}

class PasswordEntryModal extends StatefulWidget {
  const PasswordEntryModal({super.key, required this.wifiEntry});

  final WifiEntry wifiEntry;

  static Future<String?> show(context, WifiEntry entry) {
    return showPlatformDialog(context: context, builder: (context) {
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
          title: Text(
              "Enter password for '${widget.wifiEntry.name}'"
          ),
          content: PlatformTextFormField(
            obscureText: true,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onEditingComplete: _submit,
            onSaved: _value,
            cupertino: (_, __) => CupertinoTextFormFieldData(
            ),
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
          ]
      ),
    );
  }

  void _value(String? val) {
    Navigator.of(context).pop(val);
  }

  void _submit() {
    if(formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
    }
  }

}

class ProvisionSelectWifiPage extends StatelessWidget {
  const ProvisionSelectWifiPage({super.key, required this.initialState});

  final ProvisionState initialState;

  static Route<ProvisionSelectWifiPage> route(context, state) =>
      platformPageRoute(context: context, builder:
          (_) => ProvisionSelectWifiPage(initialState: state));


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProvisionProvider>(
      create: (context) => ProvisionProvider(initialState: initialState),
      child: Scaffold(
        body: Selector<ProvisionProvider, Tuple2<ProvisionStage, Object?>>(
            selector: (_, prov) => Tuple2(prov.state.stage, prov.state.error),
            builder: (_, data, __) {
              return WizardStep(
                icon: Icon(Icons.wifi),
                title: "Select Wi-Fi Network",
                subtext: "",
                child: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 40.0),
                      child: Consumer<ProvisionProvider>(
                          builder: (_, prov, child) {
                            if (prov.state.wifiNetworks == null) {
                              return Center(child: CircularProgressIndicator());
                            } else {
                              return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ...prov.state.wifiNetworks!
                                        .map((e) =>
                                        _buildWifiCard(context, e, prov))
                                        .toList(growable: false),
                                    TextButton(
                                        onPressed: () {
                                          prov.rescanNetworks();
                                        },
                                        child: Text('Rescan Networks')
                                    )
                                  ]
                              );
                            }
                          }
                      ),
                    )
                ),
              );
            }
        ),
      ),
    );
  }


  void _showPasswordDialog(BuildContext context, WifiEntry entry, ProvisionProvider prov) {
    if(prov.state.stage == ProvisionStage.select_wifi) {
      PasswordEntryModal.show(context, entry).then((value) {
        if(value != null) {
          prov.setWifiPassword(context, entry.name, value).then((value) {
            if(context.mounted) {
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

    if(prov.state.ssid == entry.name) {
      if(prov.state.error != null) {
        String text;
        if(prov.state.error is TimeoutException) {
          text = AppLocalizations.of(context)!.genericTryAgain;
        } else {
          text = prov.state.error.toString();
        }
        subtitle = Text(
          text,
          style: TextStyle(color: Theme.of(context).errorColor),
        );
      }
    }

    return Card(
      elevation: 1,
      child: ListTile(
        leading: prov.state.ssid == entry.name && prov.state.error == null
              ? SizedBox(child: const CircularProgressIndicator(), width: 24, height: 24,)
              : Icon(_wifiIcon(entry)),
        title: Text(entry.name),
        subtitle: subtitle,
        onTap: () {
          _showPasswordDialog(context, entry, prov);
        },
      ),
    );
  }

  IconData _wifiIcon(WifiEntry entry) {
    if((entry.rssi ?? 0) > -55) {
      return Icons.wifi;
    } else if((entry.rssi ?? 0) > -77  ) {
      return Icons.wifi_2_bar;
    }
    return Icons.wifi_1_bar;
  }

}

class ProvisionConnectingPage extends StatelessWidget {
  const ProvisionConnectingPage({super.key, required this.initialState});

  final ProvisionState initialState;

  static Route<ProvisionConnectingPage> route(context, state) =>
      platformPageRoute(context: context, builder:
          (_) => ProvisionConnectingPage(initialState: state));


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProvisionProvider>(
      create: (context) {
        final prov = ProvisionProvider(initialState: initialState);
        prov.finalize(context).then((value) {
          if(value.stage == ProvisionStage.complete) {
            Provider.of<DeviceListProvider>(context, listen: false)
                .refresh();
            Provider.of<SelectedDeviceProvider>(context, listen: false)
                .selectDeviceByID(value.deviceID!);

            Navigator.of(context)
                .pushNamedAndRemoveUntil('/index', (route) => false);
            Navigator.of(context)
                .pushNamed('/post_setup');
          }
        });
        return prov;
      },
      builder: (context, __) {
        return Scaffold(
          body: Selector<ProvisionProvider, Tuple2<ProvisionStage, Object?>>(
              selector: (_, prov) => Tuple2(prov.state.stage, prov.state.error),
              builder: (_, data, __) {
                return WizardStep(
                  icon: _buildIcon(context, data),
                  title: _buildTitle(data),
                  subtext: _buildSubtitle(data),
                  footer: _buildFooter(context, data),
                  child: _buildBody(context, data),
                );
              }
          ),
        );
      },
    );
  }

  Widget? _buildFooter(context, data) {
    if(data.item1 == ProvisionStage.failed || data.item2 != null) {
      return PlatformElevatedButton(
        child: Text(AppLocalizations.of(context)!.genericTryAgain),
        onPressed: () {
          Navigator.of(context).pushReplacement(ProvisionPage.route(context));
        },
      );
    } else if (data.item1 == ProvisionStage.complete) {
      return PlatformElevatedButton(
        child: Text(AppLocalizations.of(context)!.genericCompleteAction),
        onPressed: () {
          //Navigator.of(context).pushReplacement(TodayPage.route(context));
        },
      );

    }
    return null;
  }

  Widget _buildBody(context, data) {
    if(data.item1 == ProvisionStage.failed || data.item2 != null) {
      return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: ErrorInfoBox(error: data.item2),
          )
      );
    } else {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 40.0),
              child: Center(
                child: Consumer<ProvisionProvider>(
                    builder: (_, prov, child) {
                      if(prov.state.stage == ProvisionStage.complete) {
                        return Container();
                      } else if(prov.state.stage == ProvisionStage.finalizing) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: prov.state.progress,
                              semanticsLabel: 'Progress',
                            ),
                            Text('Estimated time remaining: '
                                '${(prov.state.completionETA?.inMinutes ?? 0) + 1} min.')
                          ],
                        );
                      } else {
                        return Container();
                      }
                    }
                ),
              )
          )
      );
    }
    /*if(state.stage == ProvisionStage.complete) {
      return Container();
    } else if(state.stage == ProvisionStage.finalizing) {

    } else {
      return ErrorInfoBox(error: state.error);
    }*/
  }

  Widget _buildIcon(context, data) {
    if(data.item2 != null) {
      return Icon(Icons.close, color: Theme.of(context).colorScheme.error);
    } else if(data.item1 == ProvisionStage.finalizing) {
      return const Icon(Icons.cloud_sync);
    } else if(data.item1 == ProvisionStage.complete) {
      return Icon(Icons.check_circle, color: Colors.green[700]);
    } else {
      return const Icon(Icons.question_mark);
    }
  }

  String _buildTitle(data) {
    if(data.item2 != null) {
      return "Connection Problem";
    } else if(data.item1 == ProvisionStage.finalizing) {
      return "Finishing Setup...";
    } else if(data.item1 == ProvisionStage.complete) {
      return "Setup Complete";
    } else {
      return "Error";
    }
  }

  String _buildSubtitle(data) {
    if(data.item2 != null) {
      return "There was a problem setting up your pill organizer.";
    } else if(data.item1 == ProvisionStage.finalizing) {
      return "Please wait a few minutes for your pill organizer to "
          "finish initial setup.";
    } else if(data.item1 == ProvisionStage.complete) {
      return "Your pill organizer is now ready to use.";
    } else {
      return "Error";
    }
  }

}


void startProvisioning(BuildContext context) {
  Navigator.of(context).push(ProvisionPage.route(context));
}